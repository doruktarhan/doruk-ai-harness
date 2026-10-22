#!/usr/bin/env bash
# codex-run.sh MODEL EFFORT SANDBOX WORKDIR PROMPT_FILE OUT [MAX_S=1500] [START_S=120] [QUIET_S=600]
#
# Runs one `codex exec` the way an agent must: stdin closed, a wall-clock cap, a startup
# check and a no-progress check. macOS ships no `timeout`, and the Bash tool's `timeout`
# does not apply to run_in_background, so this script is the cap. Needs bash + the
# coreutils that ship with macOS.
#
#   MODEL        gpt-6-sol | gpt-6-astra | gpt-6-luna   (pinned here, never from config.toml)
#   EFFORT       model_reasoning_effort: medium | high | max
#   SANDBOX      read-only | workspace-write
#   WORKDIR      codex -C: repo root or worktree
#   PROMPT_FILE  the prompt, read with cat and passed as one argument
#   OUT          codex's final answer; the last line is always one of
#                  CODEX_EXIT=<rc>        codex finished on its own, exit rc
#                  CODEX_KILLED=<reason>  this script killed it, exit 124
#                progress (header, session id, tool calls) goes to OUT.log
#   MAX_S        kill after this many seconds of wall clock
#   START_S      kill if no `session id:` line has appeared by then (stuck in startup)
#   QUIET_S      kill if neither OUT nor OUT.log has grown for this long
#
# Prints one heartbeat line a minute to its own stdout, so a background run's task output
# keeps growing while codex is alive, and a final line saying how it ended.
set -u
usage() { sed -n '2,24p' "$0" >&2; exit 2; }
[ $# -ge 6 ] || usage
model=$1 effort=$2 sandbox=$3 workdir=$4 prompt_file=$5 out=$6
max_s=${7:-1500} start_s=${8:-120} quiet_s=${9:-600}
[ -r "$prompt_file" ] || { echo "codex-run: cannot read prompt file $prompt_file" >&2; exit 2; }
[ -d "$workdir" ] || { echo "codex-run: no such workdir $workdir" >&2; exit 2; }
command -v codex >/dev/null || { echo "codex-run: codex not on PATH (npm i -g @openai/codex)" >&2; exit 2; }
: > "$out"; : > "$out.log"

pid=""
kill_group() { [ -n "$pid" ] && { kill -TERM -- "-$pid" 2>/dev/null; sleep 3; kill -KILL -- "-$pid" 2>/dev/null; }; }
trap 'kill_group; echo "CODEX_KILLED=wrapper received a signal" >> "$out"; exit 124' TERM INT HUP

set -m  # job control: codex gets its own process group, so one kill reaches its native child
codex exec -m "$model" -c "model_reasoning_effort=\"$effort\"" --sandbox "$sandbox" \
  -C "$workdir" "$(cat "$prompt_file")" < /dev/null > "$out" 2> "$out.log" &
pid=$!
set +m

t0=$(date +%s); last=0; changed=$t0; beat=$t0; reason=""
while kill -0 "$pid" 2>/dev/null; do
  sleep 5
  now=$(date +%s)
  size=$(( $(wc -c < "$out") + $(wc -c < "$out.log") ))
  [ "$size" -ne "$last" ] && { last=$size; changed=$now; }
  if [ $((now - t0)) -ge "$start_s" ] && ! grep -q 'session id:' "$out" "$out.log"; then
    reason="no session id after ${start_s}s (stuck in startup)"; break; fi
  [ $((now - changed)) -ge "$quiet_s" ] && { reason="no output for ${quiet_s}s"; break; }
  [ $((now - t0)) -ge "$max_s" ] && { reason="over ${max_s}s wall clock"; break; }
  [ $((now - beat)) -ge 60 ] && { beat=$now; echo "codex-run: alive $((now - t0))s, ${size} bytes of output"; }
done

if [ -n "$reason" ]; then
  kill_group
  echo "CODEX_KILLED=$reason" >> "$out"
  echo "codex-run: KILLED codex ($reason). Answer file: $out, progress: $out.log"
  exit 124
fi
wait "$pid"; rc=$?
echo "CODEX_EXIT=$rc" >> "$out"
echo "codex-run: codex exited $rc after $(( $(date +%s) - t0 ))s. Answer file: $out"
exit "$rc"
