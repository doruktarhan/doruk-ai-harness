#!/usr/bin/env bash
# foreman-hook.sh — PreToolUse hook on the Agent tool. Rewrites the spawn's input via
# `updatedInput`. Silent (no stdout) when it has nothing to change, and on any error:
# this must never break a spawn.
#
# What it does (stdin fields measured on Claude Code 2.1.322):
#   The main session spawns (stdin has no agent_id):
#     - an Opus or Fable agent gets roles/foreman.md prepended to its prompt, unless the
#       prompt's own role line says executor or leaf ("Role: executor."). Any other role
#       line ("Role: foreman, small scope", "Role: designer") still gets the rules.
#   A subagent spawns (stdin has agent_id): the new agent is a helper and gets no foreman
#     text. Its `name` is left as the foreman wrote it.
#   Either caller, Fable spawn:
#     - effort unset becomes "medium"; "xhigh" and "max" become "high".
#
# Model: tool_input.model. When it is unset the spawn inherits its caller's model, read
# from the last assistant line of the caller's transcript.
#
# Untouched: Sonnet and Haiku spawns from the main session, subagent_type "fork", and agent
# types with no Agent tool (Explore, Plan, statusline-setup, claude-code-guide, web-fetch).
#
# Why PreToolUse:Agent and not SubagentStart: SubagentStart's stdin has no model and no
# prompt, and the agent's meta.json is written after the hook returns.
dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
command -v python3 >/dev/null 2>&1 || exit 0
pycode=$(cat <<'PY'
import json, os, re, sys

SKIP_TYPES = {"fork", "explore", "plan", "statusline-setup", "claude-code-guide", "web-fetch"}


def caller_model(d):
    """Model of the agent making the call, from the tail of its transcript."""
    path = d.get("transcript_path") or ""
    if d.get("agent_id"):
        path = os.path.join(re.sub(r"\.jsonl$", "", path), "subagents",
                            "agent-%s.jsonl" % d["agent_id"])
    try:
        with open(path, "rb") as fh:
            fh.seek(max(0, os.path.getsize(path) - 400_000))
            tail = fh.read().decode("utf-8", "ignore")
        found = [m for m in re.findall(r'"model":"([^"]+)"', tail) if m != "<synthetic>"]
        return found[-1] if found else ""
    except Exception:
        return ""


def main():
    d = json.load(sys.stdin)
    if d.get("tool_name") not in ("Agent", "Task"):
        return
    ti = d.get("tool_input") or {}
    prompt = ti.get("prompt")
    if not isinstance(prompt, str):
        return
    if (ti.get("subagent_type") or "").lower() in SKIP_TYPES:
        return
    from_subagent = bool(d.get("agent_id"))
    model = (ti.get("model") or caller_model(d)).lower()
    new, notes = dict(ti), []

    if "fable" in model:
        effort = (ti.get("effort") or "").lower()
        if not effort:
            new["effort"] = "medium"
        elif effort in ("xhigh", "max"):
            new["effort"] = "high"
            notes.append("effort %s was lowered to high (the ceiling for Fable agents)" % effort)

    if not from_subagent and ("fable" in model or "opus" in model) and not re.search(
            r"^\s*role:\s*(executor|leaf)\b", prompt[:300], re.I | re.M):
        with open(os.path.join(os.environ["ORCH_DIR"], "roles", "foreman.md")) as fh:
            rules = fh.read().strip()
        new["prompt"] = rules + "\n\n---\n\nYour brief:\n\n" + prompt

    if new == ti:
        return
    out = {"hookEventName": "PreToolUse", "permissionDecision": "allow",
           "permissionDecisionReason": "orchestrate foreman-hook", "updatedInput": new}
    if notes:
        out["additionalContext"] = "orchestrate hook: " + "; ".join(notes) + "."
    sys.stdout.write(json.dumps({"hookSpecificOutput": out}) + "\n")


try:
    main()
except Exception:
    pass
PY
)
ORCH_DIR="$dir" python3 -c "$pycode" 2>/dev/null
exit 0
