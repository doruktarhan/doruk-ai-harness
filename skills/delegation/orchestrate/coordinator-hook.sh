#!/usr/bin/env bash
# coordinator-hook.sh — SessionStart hook that points coordinator-tier sessions
# (Fable/Opus) at the `orchestrate` skill. Silent for everything else, and
# silent on any error: this must never break a session start.
#
# Output contract (Claude Code SessionStart hooks):
#   {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"<text>"}}
#
# Model detection, ranked fallback chain (CLI flag > env > settings, the real
# precedence Claude Code resolves a model with):
#   1. `model` field in the hook's stdin JSON. Claude Code docs now document
#      this field; treated as authoritative when present.
#   2a. The `--model <value>` flag on the argv of the process at $CLAUDE_PID
#       (env var Claude Code sets to its own pid; confirmed present in 2.1.217).
#   2b. Fallback: walk up from $PPID (up to 3 hops, stop at pid 1) looking for
#       a "claude" process with a --model flag — covers hook invocations that
#       go through an intermediate `sh -c` wrapper, or older Claude Code
#       versions without CLAUDE_PID.
#   2c. $ANTHROPIC_MODEL env var — matters in practice for alias/proxy setups
#       (e.g. a GLM-backed session sets this) where the hook must stay silent.
#   3. `model` key in <cwd>/.claude/settings.local.json, then
#      <cwd>/.claude/settings.json, then ~/.claude/settings.json. Managed
#      settings are intentionally not checked (rare; we fail silent anyway).
# If none of these resolve a model, exit silently (no pointer, no error).
#
# Constraints: bash, POSIX-ish, no jq, no network, must fail silent (any
# error anywhere in this script must still result in exit 0 and no stdout).
# POINTER below is a fixed literal with no user-controlled input, so it is
# limited to a safe character set (letters, punctuation, backticks) by
# construction — the escaping step is belt-and-suspenders, not load-bearing.

POINTER='Coordinator-tier session. If this session turns to hands-on work, invoke the
`orchestrate` skill and follow its delegation rules — you coordinate; executors build.
Even in pure discussion/research: delegate read-heavy exploration to Sonnet scout
subagents instead of reading broadly yourself.'

# Extract a `"model"` value from a settings-shaped JSON file. Tries plutil
# (macOS-native, real JSON parse — honest against nested "model" keys under
# other objects) first, falls back to a flat grep if plutil is missing/fails
# or the file isn't a plain top-level {"model": "..."} shape.
extract_model_from_file() {
  local f="$1" val
  val="$(plutil -extract model raw -o - "$f" 2>/dev/null || true)"
  if [ -n "$val" ]; then
    printf '%s' "$val"
    return 0
  fi
  grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" 2>/dev/null | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'
}

main() {
  local stdin_json model=""

  stdin_json="$(cat 2>/dev/null || true)"

  # Defensive subagent guard: SessionStart empirically doesn't fire for
  # subagents (they get SubagentStart instead), but "agent_id" is a documented
  # stdin field for subagent-context hooks — future-proof at zero cost.
  case "$stdin_json" in
    *'"agent_id"'*) return 0 ;;
  esac

  # 1. stdin `model` field.
  model="$(printf '%s' "$stdin_json" | grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"

  # 2. Parent process argv --model flag. Hooks can run behind an intermediate
  # `sh -c` wrapper, so $PPID isn't reliably the claude process itself.
  # 2a. CLAUDE_PID env var (set by Claude Code to its own pid, confirmed present
  #     in 2.1.217) — check this process directly first, no tree walk needed.
  if [ -z "$model" ] && [ -n "${CLAUDE_PID:-}" ]; then
    local claude_cmd
    claude_cmd="$(ps -o command= -p "$CLAUDE_PID" 2>/dev/null || true)"
    case "$claude_cmd" in
      *claude*) model="$(printf '%s' "$claude_cmd" | grep -o -- '--model[= ][^ ]*' | head -1 | sed -E 's/--model[= ]//')" ;;
    esac
  fi

  # 2b. Fallback: walk up from $PPID (up to 3 hops, stop at pid 1) looking for
  # a process whose command contains "claude" and a --model flag. Covers older
  # Claude Code versions or launch paths where CLAUDE_PID isn't set.
  if [ -z "$model" ]; then
    local pid cmd hop
    pid="${PPID:-0}"
    hop=0
    while [ -n "$pid" ] && [ "$pid" != "0" ] && [ "$pid" != "1" ] && [ "$hop" -lt 3 ]; do
      hop=$((hop + 1))
      cmd="$(ps -o command= -p "$pid" 2>/dev/null || true)"
      case "$cmd" in
        *claude*)
          model="$(printf '%s' "$cmd" | grep -o -- '--model[= ][^ ]*' | head -1 | sed -E 's/--model[= ]//')"
          [ -n "$model" ] && break
          ;;
      esac
      pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
    done
  fi

  # 2c. ANTHROPIC_MODEL env var (proxy/alias sessions — e.g. GLM — set this;
  # the hook must stay silent for those, so check it before settings files).
  if [ -z "$model" ] && [ -n "${ANTHROPIC_MODEL:-}" ]; then
    model="$ANTHROPIC_MODEL"
  fi

  # 3. cwd settings.local.json, then cwd settings.json, then user settings.json.
  if [ -z "$model" ]; then
    local cwd settings_local="" settings_project="" settings_user=""
    cwd="$(printf '%s' "$stdin_json" | grep -o '"cwd"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"
    if [ -n "$cwd" ] && [ -f "$cwd/.claude/settings.local.json" ]; then
      settings_local="$cwd/.claude/settings.local.json"
    fi
    if [ -n "$cwd" ] && [ -f "$cwd/.claude/settings.json" ]; then
      settings_project="$cwd/.claude/settings.json"
    fi
    if [ -f "$HOME/.claude/settings.json" ]; then
      settings_user="$HOME/.claude/settings.json"
    fi
    for f in "$settings_local" "$settings_project" "$settings_user"; do
      [ -n "$f" ] || continue
      [ -f "$f" ] || continue
      model="$(extract_model_from_file "$f")"
      [ -n "$model" ] && break
    done
  fi

  [ -z "$model" ] && return 0

  # Match coordinator-tier: fable or opus, case-insensitive substring.
  local model_lc
  model_lc="$(printf '%s' "$model" | tr '[:upper:]' '[:lower:]')"
  case "$model_lc" in
    *fable*|*opus*)
      local escaped
      escaped="$(printf '%s' "$POINTER" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g')"
      [ -n "$escaped" ] || return 0
      printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped"
      ;;
    *)
      return 0
      ;;
  esac
}

main 2>/dev/null
exit 0
