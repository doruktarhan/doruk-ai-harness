#!/usr/bin/env bash
# foreman-hook.sh — PreToolUse hook on the Agent tool. When a spawn will run on
# Fable or Opus and its prompt names no role, prepends the foreman role line to
# the prompt via `updatedInput`. Silent (no stdout) in every other case and on
# any error: this must never break a spawn.
#
# Why PreToolUse:Agent and not SubagentStart (measured on Claude Code 2.1.303):
#   - SubagentStart stdin carries session_id, transcript_path, cwd, scratchpad_dir,
#     prompt_id, agent_id, agent_type, hook_event_name. No model, no prompt.
#   - <transcript dir>/<session_id>/subagents/agent-<agent_id>.meta.json does hold
#     "model", but it is written after the hook returns (absent after 5 s of polling).
#   - The parent transcript holds the batch's Agent tool_use inputs, but two agents
#     spawned in one parallel message cannot be told apart from the hook.
#   PreToolUse gets the exact tool_input (model, prompt, subagent_type) per spawn,
#   and its additionalContext/updatedInput is verified to reach the subagent.
#
# Model resolution: tool_input.model; if absent or subagent_type is "fork" (both
# inherit the parent's model) the parent model via CLAUDE_PID argv --model, then
# $ANTHROPIC_MODEL, then the `model` key of <cwd>/.claude/settings.local.json,
# <cwd>/.claude/settings.json, ~/.claude/settings.json.
#
# Silent for: Sonnet/Haiku/unknown model; a prompt that already opens a line with
# "Role:" within its first 300 characters (so "Role: executor." wins); agent types
# that have no Agent tool (Explore, Plan, statusline-setup, claude-code-guide).
#
# Output contract (PreToolUse):
#   {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow",
#     "updatedInput":{...tool_input with prompt prefixed...}}}
#
# Constraints: bash + python3 (already required by the safety_guard PreToolUse
# hook), no jq, no network, fail silent: any error still exits 0 with no stdout.

main() {
  command -v python3 >/dev/null 2>&1 || return 0
  # The script travels in a variable and runs via -c so the hook's stdin (the
  # PreToolUse JSON) stays available to python's sys.stdin.
  local pycode
  read -r -d '' pycode <<'PY' || true
import json, os, re, subprocess, sys

TEXT = (
    "Role: foreman (default for a Fable or Opus spawn; a role named elsewhere in this "
    "prompt wins). You may spawn Sonnet leaves, never another foreman, and you report to "
    "whoever spawned you. Delegate exploration and discovery (finding files, reading code "
    "or data to learn what is there), extraction, analysis, scripts and other labor to "
    "Sonnet, in review, design and spec jobs too. Do yourself only what you were called "
    "for: the review verdict and the reading it needs, the design, the spec, the final "
    "page or dashboard. Spawn leaves without `name` and message them later by the agentId "
    "their spawn returned: an unnamed leaf or your own background Bash wakes you when it "
    "finishes, a named one reports to an inbox nobody reads. End a turn only while such a "
    "waker is pending; to wait on anything else, launch a background waiter with a deadline. "
    "Run Codex only through ~/.claude/skills/codex/scripts/codex-run.sh."
)
SILENT_TYPES = {"explore", "plan", "statusline-setup", "claude-code-guide"}


def parent_model(cwd):
    pid = os.environ.get("CLAUDE_PID")
    if pid:
        try:
            cmd = subprocess.run(["ps", "-o", "command=", "-p", pid],
                                 capture_output=True, text=True, timeout=2).stdout
            m = re.search(r"--model[= ](\S+)", cmd)
            if m:
                return m.group(1)
        except Exception:
            pass
    if os.environ.get("ANTHROPIC_MODEL"):
        return os.environ["ANTHROPIC_MODEL"]
    for f in (os.path.join(cwd, ".claude", "settings.local.json"),
              os.path.join(cwd, ".claude", "settings.json"),
              os.path.expanduser("~/.claude/settings.json")):
        try:
            with open(f) as fh:
                v = json.load(fh).get("model")
            if isinstance(v, str) and v:
                return v
        except Exception:
            pass
    return ""


def main():
    d = json.load(sys.stdin)
    if d.get("tool_name") not in ("Agent", "Task"):
        return
    ti = d.get("tool_input") or {}
    prompt = ti.get("prompt")
    if not isinstance(prompt, str):
        return
    if re.search(r"^\s*role:", prompt[:300], re.I | re.M):
        return
    stype = (ti.get("subagent_type") or "")
    if stype.lower() in SILENT_TYPES:
        return
    model = ti.get("model") or ""
    if not model or stype == "fork":
        model = parent_model(d.get("cwd") or os.getcwd())
    model = model.lower()
    if "fable" not in model and "opus" not in model:
        return
    new = dict(ti)
    new["prompt"] = TEXT + "\n\n" + prompt
    out = {"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                  "permissionDecision": "allow",
                                  "permissionDecisionReason": "foreman-hook: Fable/Opus spawn, foreman line prepended",
                                  "updatedInput": new}}
    sys.stdout.write(json.dumps(out) + "\n")


try:
    main()
except Exception:
    pass
PY
  [ -n "$pycode" ] || return 0
  python3 -c "$pycode"
}

main 2>/dev/null
exit 0
