#!/usr/bin/env bash
# depth-gauge.sh — measure each subagent's live context from its transcript.
#
# Usage: depth-gauge.sh [session-dir]
#   session-dir: a Claude Code session directory (or its subagents/ subdir), e.g.
#     ~/.claude/projects/<project-slug>/<session-id>
#   Defaults to the current directory.
#
# Live context = input_tokens + cache_read_input_tokens + cache_creation_input_tokens
# from the LAST "usage" object in each agent-*.jsonl. This is a measurement of what the
# agent's context actually holds — use it instead of the agent's own "% full" guess.
# Rule of thumb: past ~50-60% of the agent's window, no new tasks (questions/revisions ok).
set -euo pipefail

dir="${1:-.}"
[ -d "$dir/subagents" ] && dir="$dir/subagents"

shopt -s nullglob
files=("$dir"/agent-*.jsonl)
if [ ${#files[@]} -eq 0 ]; then
  echo "no agent-*.jsonl transcripts found in $dir" >&2
  exit 1
fi

printf '%-45s %-22s %10s  %s\n' "AGENT" "MODEL" "LIVE CTX" "(input + cache_read + cache_creation)"
for f in "${files[@]}"; do
  name=$(basename "$f" .jsonl)
  model=$(grep -o '"model":"[^"]*"' "$f" | grep -v '<synthetic>' | tail -1 | cut -d'"' -f4)
  usage=$(grep -o '"usage":{[^}]*' "$f" | tail -1)
  if [ -z "$usage" ]; then
    printf '%-45s %-22s %10s\n' "$name" "${model:-?}" "no usage"
    continue
  fi
  get() { echo "$usage" | grep -o "\"$1\":[0-9]*" | head -1 | cut -d: -f2; }
  in=$(get input_tokens); in=${in:-0}
  cr=$(get cache_read_input_tokens); cr=${cr:-0}
  cc=$(get cache_creation_input_tokens); cc=${cc:-0}
  live=$((in + cr + cc))
  printf '%-45s %-22s %9dk  (%d + %d + %d)\n' "$name" "${model:-?}" "$((live / 1000))" "$in" "$cr" "$cc"
done
