# agent-watch.py — the overnight watchdog

`agent-watch.py` (in the skill folder) reads one session's transcripts, task outputs, team
inbox and `ps`, prints one line per stall and nothing when healthy. It never messages or
kills anything; the coordinator does that. Why it exists: `../references/rationale.md`,
"The 2026-10-22 overnight stall".

## Start it

From the coordinator, once hands-on overnight work begins, with `CronCreate`
(`cron: "*/20 * * * *"`, `recurring: true`), where `<scratchpad>` is your scratchpad
directory, `<start>` the build's start time in UTC ISO, and `<state>` any file under the
scratchpad:

```
Watchdog run. Execute exactly:
python3 -I ~/.claude/skills/orchestrate/agent-watch.py <scratchpad> --since <start> --state <state>
If it prints nothing, end the turn without saying anything. Otherwise act on each line as
`~/.claude/skills/orchestrate/references/watchdog.md` says, and post to Doruk only when you
took an action or could not resolve a line.
```

`--state` makes each flag print once; an IDLE, STALE or CODEX flag that is still true an
hour later prints again (`--repeat-min 60`), a LOST item never does. Delete the cron when
the build lands. The script takes the session dir `~/.claude/projects/<slug>/<session-id>`
too, and `--now ISO` replays the past (used to verify it against the 2026-10-22 session).

## What each line means and what to do

| Line | Meaning | Action |
|------|---------|--------|
| `LOST <ts> <helper> -> <parent> (done\|message): …` | A named helper's report sits unread in the team inbox. Its parent never got it. | Read the full item in `~/.claude/teams/session-<id8>/inboxes/team-lead.json` and `SendMessage` the result text to `<parent>`. If the parent is `coordinator`, it is yours: act on it. |
| `IDLE <agent> (<label>) waiting N min, nothing pending: …` | The agent ended its turn saying it waits, and nothing it launched is still running. Nothing will wake it. | Check what it waits on (git log in its worktree, the files it named, its helpers' transcripts) and message it what landed, or that nothing did. A stale IDLE that repeats after a nudge is a dead agent: respawn with a successor brief. |
| `STALE <task> by <agent> (…) 'bash <description>': launched N min ago, output quiet M min: <file>` | A background command has produced no output for `--stale-min` minutes. A `codex-run.sh` run prints a heartbeat every minute, so a quiet one is dead or killed. Commands that write only to their own files look quiet while healthy. | `ps -axo pid,etime,time,command \| grep <something from the description>`. CPU time growing or its own output files growing: leave it. Otherwise kill the process group and tell the owning agent which task died. |
| `CODEX pid N alive M min: …` | A `codex exec` that is not under `codex-run.sh` has lived past `--codex-min`. Wrapper-owned runs are skipped, since the wrapper caps them. | `kill -TERM -- -<pgid>` (the pgid from `ps -o pgid= -p N`), then tell its owner to rerun through the wrapper. |

Thresholds: `--idle-min 15`, `--stale-min 20`, `--codex-min 30` by default; raise
`--stale-min` for builds whose commands legitimately run silent for longer.

Done: the cron exists for the night, every printed line got its action, and the cron is
deleted when the build lands.
