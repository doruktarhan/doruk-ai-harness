#!/usr/bin/env bash
# main-hook.sh — SessionStart hook. Injects roles/main.md (the main-session orchestration
# rules) as additionalContext. Fires on startup, resume, clear and after compaction, so the
# rules come back after a context wipe.
#
# Registered per project (the project's .claude/settings.json), not in the user settings:
# Doruk's call on 2026-11-11, so only projects that orchestrate carry the text.
#
# No model check, on purpose (measured on Claude Code 2.1.322): the SessionStart stdin
# carries no model, and a session started as `claude` with settings model "sonnet" and then
# switched with /model cannot be told from a Sonnet session. The text opens by saying when
# it applies, so a session that never spawns an agent ignores it.
#
# Silent for subagents (stdin has agent_id) and on any error: never break a session start.
dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
command -v python3 >/dev/null 2>&1 || exit 0
ORCH_DIR="$dir" python3 -c '
import json, os, sys
try:
    d = json.load(sys.stdin)
    if d.get("agent_id"):
        sys.exit(0)
    with open(os.path.join(os.environ["ORCH_DIR"], "roles", "main.md")) as fh:
        text = fh.read().strip()
    if text:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart",
                                                 "additionalContext": text}}))
except Exception:
    pass
' 2>/dev/null
exit 0
