#!/usr/bin/env python3
"""agent-watch.py <session-dir | scratchpad-dir> [--since ISO] [--now ISO] [--state FILE]
                  [--idle-min 15] [--stale-min 20] [--codex-min 30] [--repeat-min 60]

Quiet watchdog for one Claude Code session tree. Prints one line per anomaly and nothing
when healthy; exit 0 always (an internal error prints one `agent-watch: error` line to
stderr). Reads local files and `ps`; writes only the --state file.

  LOST   an unread item in the session team inbox (~/.claude/teams/session-<id8>/inboxes/
         team-lead.json). A helper spawned with `name` reports there, and nothing delivers it
         to the agent that spawned the helper.
  IDLE   an agent whose last act was ending a turn with waiting-style text while nothing it
         launched (unnamed agent, background Bash) is still pending, so nothing will wake it.
  STALE  a background Bash job launched by an agent, not yet reported finished, whose output
         file has not grown for --stale-min minutes.
  CODEX  a live `codex exec` older than --codex-min minutes that no codex-run.sh wrapper owns
         (the wrapper caps its own runs). Skipped under --now.

The argument may be the session dir (~/.claude/projects/<slug>/<session-id>) or anything
under the session scratchpad (/private/tmp/claude-<uid>/<slug>/<session-id>/...).
--since limits inbox items, turn ends and job launches to those after ISO (set it to the
build's start). --now replays the past. --state FILE remembers what was printed: a LOST
item prints once, the others print again if still true after --repeat-min minutes.
"""
import json, os, re, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

WAIT = re.compile(r"\bwait(s|ing)?\b|in flight|outstanding|still running|depends on|"
                  r"(continue|pick (it |this )?up|resume|proceed) when|once .{0,60}(lands|reports|finishes|arrives)",
                  re.I)
TASK_ID = re.compile(r"<task-id>([^<]+)</task-id>")
AGENT_LAUNCH = re.compile(r"agentId: (\S+)")


def ts(s):
    d = datetime.fromisoformat(s.replace("Z", "+00:00"))
    return d if d.tzinfo else d.replace(tzinfo=timezone.utc)


def iso(d):
    """Canonical transcript form, so string order is time order."""
    return d.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "Z"


def locate(arg):
    """Return (session_dir, tasks_dir, session_id) from either kind of path."""
    p = Path(arg).expanduser().resolve()
    parts = p.parts
    if any(x.startswith("claude-") for x in parts) and "tmp" in parts:
        i = next(i for i, x in enumerate(parts) if x.startswith("claude-"))
        slug, sid = parts[i + 1], parts[i + 2]
        tasks = Path(*parts[: i + 3]) / "tasks"
        sess = Path.home() / ".claude" / "projects" / slug / sid
    else:
        sess = p if p.is_dir() else p.parent
        if sess.name == "subagents":
            sess = sess.parent
        sid, slug = sess.name, sess.parent.name
        tasks = Path(f"/private/tmp/claude-{os.getuid()}") / slug / sid / "tasks"
    return sess, tasks, sid


def records(path):
    with open(path) as fh:
        for line in fh:
            try:
                yield json.loads(line)
            except Exception:
                continue


def scan(path, now_iso):
    """One pass over a transcript. Returns (last_turn, pending, launched).

    last_turn: (timestamp, text) when the newest assistant record ended a turn with text.
    pending:   {task_id: (launch_ts, label)} launched here and not yet reported finished.
    """
    last_turn = None
    pending, descr = {}, {}
    for d in records(path):
        t = d.get("timestamp", "")
        typ = d.get("type")
        # api-request-* records carry no timestamp and embed the whole history: skip them
        if not t or t > now_iso or typ not in ("user", "assistant", "attachment"):
            continue
        if typ == "assistant":
            msg = d.get("message", {})
            for c in msg.get("content", []):
                if c.get("type") == "tool_use":
                    inp = c.get("input") or {}
                    descr[c.get("id")] = inp.get("description") or inp.get("command", "")[:60] or c.get("name", "")
            if msg.get("stop_reason") == "end_turn":
                txt = " ".join(c.get("text", "") for c in msg.get("content", []) if c.get("type") == "text")
                last_turn = (t, txt) if txt.strip() else None
            else:
                last_turn = None
            continue
        if typ == "user":
            tur = d.get("toolUseResult") or {}
            bid = tur.get("backgroundTaskId") if isinstance(tur, dict) else None
            content = d.get("message", {}).get("content", [])
            if isinstance(content, list):
                for c in content:
                    if c.get("type") != "tool_result":
                        continue
                    body = c.get("content")
                    text = body if isinstance(body, str) else " ".join(x.get("text", "") for x in (body or []) if isinstance(x, dict))
                    if bid:  # one toolUseResult per record: it belongs to this tool_result
                        pending[bid] = (t, "bash " + descr.get(c.get("tool_use_id"), "")[:60])
                        bid = None
                    elif "Async agent launched" in text:
                        m = AGENT_LAUNCH.search(text)
                        if m:
                            pending[m.group(1)] = (t, "agent " + descr.get(c.get("tool_use_id"), "")[:60])
        # task notifications arrive as attachments (subagents) or user messages (main session)
        s = json.dumps(d)
        if "<task-notification>" in s:
            for tid in TASK_ID.findall(s):
                if "waiting on its own background work" in s:
                    continue  # the child will notify again
                pending.pop(tid, None)
    return last_turn, pending


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    opt = {k: v for k, v in zip(args[1::2], args[2::2])}
    idle_min = float(opt.get("--idle-min", 15))
    stale_min = float(opt.get("--stale-min", 20))
    codex_min = float(opt.get("--codex-min", 30))
    repeat_min = float(opt.get("--repeat-min", 60))
    since = iso(ts(opt["--since"])) if "--since" in opt else ""
    replay = "--now" in opt
    now = ts(opt["--now"]) if replay else datetime.now(timezone.utc)
    now_iso = iso(now)
    state_file = Path(opt["--state"]).expanduser() if "--state" in opt else None
    seen = {}  # flag key -> when it was last printed
    if state_file and state_file.exists():
        for row in state_file.read_text().splitlines():
            k, _, t = row.rpartition("\t")
            if k:
                seen[k] = t

    def flag(key, line):
        last = seen.get(key)
        if last and (key.startswith("LOST") or (now - ts(last)).total_seconds() < repeat_min * 60):
            return
        seen[key] = now_iso
        print(line)
    sess, tasks, sid = locate(args[0])

    metas = {}
    for m in (sess / "subagents").glob("agent-*.meta.json"):
        try:
            metas[m.name[len("agent-"):-len(".meta.json")]] = json.loads(m.read_text())
        except Exception:
            pass
    by_name = {v["name"]: k for k, v in metas.items() if v.get("name")}

    # LOST: unread team-inbox items after --since.
    inbox = Path.home() / ".claude/teams" / f"session-{sid[:8]}" / "inboxes/team-lead.json"
    try:
        for msg in json.loads(inbox.read_text()):
            if msg.get("read") or not (since <= msg.get("timestamp", "") <= now_iso):
                continue
            name = msg.get("from", "?")
            parent = metas.get(by_name.get(name, ""), {}).get("parentAgentId") or "coordinator"
            text = msg.get("text", "")
            kind = "done" if '"idle_notification"' in text else "message"
            flag(f"LOST {msg['timestamp']} {name}",
                 f"LOST {msg['timestamp']} {name} -> {parent} ({kind}): {(msg.get('summary') or text)[:140]!r}")
    except FileNotFoundError:
        pass

    # IDLE and STALE from every transcript: main session plus each subagent.
    transcripts = [("coordinator", sess.with_suffix(".jsonl"))]
    transcripts += [(aid, sess / "subagents" / f"agent-{aid}.jsonl") for aid in metas]
    for aid, path in transcripts:
        if not path.exists():
            continue
        meta = metas.get(aid, {})
        last_turn, pending = scan(path, now_iso)
        label = meta.get("name") or meta.get("description", "")[:40]
        if aid != "coordinator" and not meta.get("name") and last_turn and last_turn[0] >= since \
                and WAIT.search(last_turn[1][-400:]) and not pending:
            age = (now - ts(last_turn[0])).total_seconds() / 60
            if age >= idle_min:
                flag(f"IDLE {aid} {last_turn[0]}",
                     f"IDLE {aid} ({label}) waiting {age:.0f} min, nothing pending: {last_turn[1][:140]!r}")
        for tid, (t_launch, what) in pending.items():
            if not what.startswith("bash") or t_launch < since:
                continue  # a pending agent shows up as IDLE/STALE under its own id
            age = (now - ts(t_launch)).total_seconds() / 60
            if age < stale_min:
                continue
            f = tasks / f"{tid}.output"
            try:
                mtime = datetime.fromtimestamp(f.stat().st_mtime, timezone.utc)
                quiet = (now - mtime).total_seconds() / 60
                if quiet < 0:
                    quiet_s = "unknown (replay)"  # the file changed after --now
                elif quiet < stale_min:
                    continue
                else:
                    quiet_s = f"{min(quiet, age):.0f} min"
            except FileNotFoundError:
                quiet_s = "no file"
            flag(f"STALE {tid}",
                 f"STALE {tid} by {aid} ({label}) {what!r}: launched {age:.0f} min ago, "
                 f"output quiet {quiet_s}: {f}")

    # CODEX: long-lived codex exec processes with no wrapper above them, live only.
    if not replay:
        out = subprocess.run(["ps", "-axo", "pid=,ppid=,etime=,command="], capture_output=True, text=True).stdout
        procs = {}
        for row in out.splitlines():
            try:
                pid, ppid, etime, cmd = row.strip().split(None, 3)
                procs[pid] = (ppid, etime, cmd)
            except ValueError:
                continue

        def wrapped(pid, hops=4):
            while hops and pid in procs:
                ppid, _, cmd = procs[pid]
                if "codex-run.sh" in cmd:
                    return True
                pid, hops = ppid, hops - 1
            return False

        for pid, (ppid, etime, cmd) in procs.items():
            if "codex exec" not in cmd or "agent-watch" in cmd or wrapped(pid):
                continue
            parts = [int(p) for p in re.split(r"[-:]", etime)]
            while len(parts) < 4:
                parts.insert(0, 0)
            minutes = parts[0] * 1440 + parts[1] * 60 + parts[2] + parts[3] / 60
            if minutes >= codex_min:
                flag(f"CODEX {pid}", f"CODEX pid {pid} alive {minutes:.0f} min: {cmd[:120]}")

    if state_file:
        state_file.parent.mkdir(parents=True, exist_ok=True)
        state_file.write_text("".join(f"{k}\t{t}\n" for k, t in sorted(seen.items())))


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        pass
    except Exception as e:  # never fail the cron; say what broke
        print(f"agent-watch: error {type(e).__name__}: {e}", file=sys.stderr)
