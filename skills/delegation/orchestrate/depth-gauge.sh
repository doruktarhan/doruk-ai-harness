#!/usr/bin/env bash
# depth-gauge.sh — how much context each subagent holds, measured from its transcript.
#
#   depth-gauge.sh [session-dir] [--all]     table of live agents, largest first
#   depth-gauge.sh --hook                    hook mode (reads the hook JSON on stdin)
#
# session-dir is ~/.claude/projects/<project-slug>/<session-id> (or its subagents/ folder).
# Without it, the session is found from $CLAUDE_CODE_SESSION_ID, which the Bash tool sets.
#
# Every agent of a session, at any depth, named or not, writes
# <session-dir>/subagents/agent-<id>.jsonl plus agent-<id>.meta.json (model, effort,
# description, parentAgentId, finished). Live context = input_tokens +
# cache_read_input_tokens + cache_creation_input_tokens of the last "usage" object.
# Checked against the last assistant message of 284 transcripts on 2026-11-11: 0 differ.
#
# The table lists agents whose transcript was written in the last 12 h, and marks the ones
# whose meta.json says finished (a finished agent can still be messaged and resumed; named
# teammates never get the flag). --all lists every agent of the session.
#
# Hook mode warns the main session and never blocks. Register it on two events:
#   UserPromptSubmit         every live agent that crossed a line since the last warning
#   PreToolUse:SendMessage   the agent being messaged
# Lines: NUDGE at 250k (ask for a handoff), STOP at 350k (no new tasks). A NUDGE prints once
# per agent; a STOP prints once on UserPromptSubmit and on every SendMessage to that agent.
# Silent when the caller is a subagent, when nothing crossed, and on any error.
# Override for tests: ORCH_NUDGE_K, ORCH_STOP_K.
command -v python3 >/dev/null 2>&1 || exit 0
pycode=$(cat <<'PY'
import glob, json, os, re, sys, tempfile, time

NUDGE = int(os.environ.get("ORCH_NUDGE_K", "250")) * 1000
STOP = int(os.environ.get("ORCH_STOP_K", "350")) * 1000
LIVE_S = 12 * 3600


def ctx(path):
    with open(path, "rb") as fh:
        fh.seek(max(0, os.path.getsize(path) - 600_000))
        tail = fh.read().decode("utf-8", "ignore")
    usage = re.findall(r'"usage":\{[^}]*', tail)
    if not usage:
        return None
    u = usage[-1]
    return sum(int(m.group(1)) for k in ("input_tokens", "cache_read_input_tokens",
                                         "cache_creation_input_tokens")
               for m in [re.search(r'"%s":(\d+)' % k, u)] if m)


def agents(sub, everything=False):
    now = time.time()
    for t in glob.glob(os.path.join(sub, "agent-*.jsonl")):
        try:
            with open(t[:-6] + ".meta.json") as fh:
                meta = json.load(fh)
        except Exception:
            meta = {}
        age = now - os.path.getmtime(t)
        if not everything and age > LIVE_S:
            continue
        try:
            size = ctx(t)
        except Exception:
            size = None
        yield {"id": os.path.basename(t)[6:-6], "meta": meta, "age": age, "ctx": size}


def label(a):
    m = a["meta"]
    return "%s (%s, %s)" % (m.get("description") or m.get("name") or "agent",
                            m.get("name") or a["id"], m.get("model") or "?")


def table(args):
    everything = "--all" in args
    args = [x for x in args if x != "--all"]
    if args:
        d = os.path.expanduser(args[0])
    else:
        sid = os.environ.get("CLAUDE_CODE_SESSION_ID", "")
        hits = glob.glob(os.path.expanduser("~/.claude/projects/*/%s" % sid)) if sid else []
        d = hits[0] if hits else "."
    sub = os.path.join(d, "subagents") if os.path.isdir(os.path.join(d, "subagents")) else d
    rows = sorted(agents(sub, everything), key=lambda a: -(a["ctx"] or 0))
    if not rows:
        print("no %sagents in %s" % ("" if everything else "recent ", sub))
        return
    print("%8s  %-7s %-7s %6s  %-5s %s" % ("CONTEXT", "MODEL", "EFFORT", "QUIET", "DEPTH", "AGENT"))
    for a in rows:
        m = a["meta"]
        size = "%dk" % (a["ctx"] // 1000) if a["ctx"] is not None else "?"
        flag = " STOP" if (a["ctx"] or 0) >= STOP else " NUDGE" if (a["ctx"] or 0) >= NUDGE else ""
        print("%8s  %-7s %-7s %5dm  %-5s %s  %s%s%s" % (
            size, m.get("model") or "?", m.get("effort") or "-", a["age"] // 60,
            m.get("spawnDepth", "?"), m.get("name") or a["id"], m.get("description") or "",
            " [finished]" if m.get("finished") else "", flag))


def hook():
    d = json.load(sys.stdin)
    if d.get("agent_id"):
        return
    event = d.get("hook_event_name")
    sub = os.path.join(re.sub(r"\.jsonl$", "", d.get("transcript_path") or ""), "subagents")
    if not os.path.isdir(sub):
        return
    state_path = os.path.join(tempfile.gettempdir(),
                              "orchestrate-depth-%s.json" % d.get("session_id", "x"))
    try:
        with open(state_path) as fh:
            state = json.load(fh)
    except Exception:
        state = {}
    target = None
    if event == "PreToolUse":
        if d.get("tool_name") != "SendMessage":
            return
        target = str((d.get("tool_input") or {}).get("to") or "")
        if not target:
            return
    lines = []
    for a in agents(sub, everything=bool(target)):
        size, name = a["ctx"] or 0, a["meta"].get("name")
        if target and target not in (a["id"], name):
            continue
        band = 2 if size >= STOP else 1 if size >= NUDGE else 0
        seen = state.get(a["id"], 0)
        own = a["meta"].get("spawnDepth", 1) <= 1
        if not own and a["meta"].get("finished"):
            continue
        k = size // 1000
        if band == 2 and (target or seen < 2):
            lines.append(("%s holds %dk tokens. Questions only from here; new tasks go to a "
                          "fresh agent. If it has written no handoff yet, ask for one now."
                          if own else
                          "Helper %s holds %dk tokens. Tell its foreman to collect what it "
                          "has and replace it.") % (label(a), k))
        elif band == 1 and seen < 1 and own:
            lines.append("%s holds %dk tokens. In your next message to it, ask it to write "
                         "its handoff in the feature folder at its next checkpoint, then "
                         "open a fresh foreman from that handoff." % (label(a), k))
        if band > seen:
            state[a["id"]] = band
    try:
        with open(state_path, "w") as fh:
            json.dump(state, fh)
    except Exception:
        pass
    if lines:
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": event,
            "additionalContext": "Agent context check (orchestrate):\n- " + "\n- ".join(lines)}}))


if "--hook" in sys.argv[1:]:
    try:
        hook()
    except Exception:
        pass
else:
    table(sys.argv[1:])
PY
)
python3 -c "$pycode" "$@"
exit 0
