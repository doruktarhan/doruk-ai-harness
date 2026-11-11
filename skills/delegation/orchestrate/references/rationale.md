# orchestrate — rationale and incident log

Background for the rules in `SKILL.md` and the two role files. Not needed in the hot path; read when a rule looks
arbitrary or when you are tempted to change one.

## Why models are tiered this way (v3 background)

v4 routes by size instead; see "The 2026-11-11 rewrite" below. The Codex tiers still hold.

- **Opus drafts, Fable reviews (constrained work).** Reviewing a design costs roughly 5% of
  producing one, so the expensive model is spent on the judgment call, not the typing.
- **Luna at max effort for background labor** (trial started 2026-08-03). It draws on a
  separate quota pool from Claude Max, and latency stops mattering once the coordinator has
  moved to another thread. Sonnet stays the default for labor you expect to iterate on
  mid-flight, because a warm Claude agent beats `codex exec resume`.
- **Never Haiku for labor.** Rework has repeatedly cost more than the token savings.
- **Never Luna or a smaller Codex tier as reviewer.** A weak reviewer produces false
  confidence, which is worse than no gate.
- **Astra only for heavyweight artifacts.** Astra on a routine diff is money burned; Sol at
  medium effort catches routine defects.
- **Explicit `model` on every spawn.** A coordinator running as Fable that forgets the flag
  silently spawns everything at Fable cost. Same failure shape on the Codex side:
  `~/.codex/config.toml` holds whatever was last set interactively, so an unpinned
  `codex exec` silently retiers the work.

## Why skills are written by the coordinator

A skill is the top model's knowledge packaged for smaller models. A Sonnet-written skill
encodes Sonnet's gaps, which then propagate to every future retrieval. Decision made
2026-09-15. The coordinator probes the real system (APIs, tools) itself before writing, then
validates with one fresh Sonnet run allowed to read only the skill file. Executors may
produce input material such as probe logs and field dumps, never the skill text.

## Persistent agents — the measurements behind the thresholds

- A 476k-token builder stayed sharp on a 1M-token window, which is why depth alone is not a
  retirement trigger.
- That evidence does not transfer: subagents in this harness were measured at roughly 200k
  windows during the skill-builder incident, 2026-07-22. Confirm the window per environment
  before leaning on depth; never assume 1M.
- Hence window-relative thresholds rather than absolute ones. The old ~150k "deep" marker
  only ever made sense on a 1M window.
- Self-reported percentages are model guesses with no denominator, which is why reports use
  absolute tokens plus an assumed window and the coordinator measures with
  `depth-gauge.sh` before reusing an agent for new work.
- The one named mistake: re-spawning fresh for a *revision* of work an existing agent
  already did re-buys context the team already paid for.
- **The warm-reuse pull.** After a session where persistence paid off, the coordinator will
  feel like handing new work to a warm agent. That feeling is the bug, not a signal.
- A retiring agent's successor note exists because the coordinator's own record is too
  distilled to reconstruct a build's decisions, file map, gotchas, and dead ends.

## Splitting big work — the 2026-09-27 incident

Designing a large event-driven engine in another project:

- Two spec agents briefed "read all of this, then design the whole thing" reached 485k and
  430k tokens, mostly from reading before writing. A research scout given seven questions
  in one brief ran 30 minutes to 331k.
- What worked afterwards: a short global plan with named pieces and exact seams; one small
  reviewer per piece, each given only its sections and `file:line` anchors. Six such reviews
  finished in about 8 minutes and found far more than one whole-document review.
- A separate consistency check read only the document and looked only at the seams between
  pieces. The coordinator kept the global picture and did not read the piece inputs itself.
- Doruk: "We shouldn't be delegating everything with: this is the whole code base, just go
  through it and design." He wants it as coordinator judgment, not a strict rule: small or
  tightly coupled work stays with one agent.

## Known future upgrades (not built)

- A tmux-backed control layer giving Codex executors real session continuity.
- Migration of review gates to `openai/codex-plugin-cc` (`/codex:review`,
  `/codex:adversarial-review`). Gate language in `SKILL.md` is deliberately
  mechanism-neutral so the migration only swaps the how.

## Operational detail

### depth-gauge.sh

`depth-gauge.sh <session-dir>` reads each subagent transcript at
`~/.claude/projects/<proj>/<session>/subagents/agent-*.jsonl`, takes the last `"usage"`
object, and reports live context as
`input_tokens + cache_read_input_tokens + cache_creation_input_tokens`.

### Codex invocation shapes

Labor and review are two different models through one CLI, never the same call, each pinned
explicitly. All go through the wrapper
`~/.claude/skills/codex/scripts/codex-run.sh MODEL EFFORT SANDBOX WORKDIR PROMPT_FILE OUT [MAX_S] [START_S] [QUIET_S]`:

```bash
W=~/.claude/skills/codex/scripts/codex-run.sh
# labor, in a worktree
$W gpt-6-luna  max    workspace-write <worktree> /tmp/codex_task.txt   /tmp/codex_task_out.txt 3600
# review
$W gpt-6-sol   medium read-only       <repo>     /tmp/codex_prompt.txt /tmp/codex_review.txt   1500
# heavyweight review (codex-cli 0.153.4+)
$W gpt-6-astra medium read-only       <repo>     /tmp/codex_prompt.txt /tmp/codex_review.txt   1500
```

Launch with `run_in_background`, then wait in the foreground for the final line (the wait
loop is in the `codex` skill). OUT ends with `CODEX_EXIT=<rc>`
or `CODEX_KILLED=<reason>`; progress and the session id are in `OUT.log`.

Luna executors are Bash processes, not Claude subagents: no `SendMessage`, no
`depth-gauge.sh`, no `ROLE:` enforcement, and the persistent-agent rules do not apply to
them.

## The 2026-10-22 overnight stall

Four stalls, 1 h 46 min to 5 h 54 min each, in one overnight build; two other foremen
never woke at all the night before.

- **Named helpers report to the wrong inbox.** With `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`,
  an `Agent` call with `name` makes a session teammate whose done notice and messages go to
  `~/.claude/teams/session-<id8>/inboxes/team-lead.json`. 48 of 48 items there were unread.
  Unnamed helpers and background Bash reliably wake their parent, so the old hook line
  ("background leaves do not wake you") was wrong. Hence: no `name`, message by `agentId`.
- **Codex hung at startup for 2 h 23 min** with no session file and 0.19 s of CPU. No
  `< /dev/null`, no working cap (macOS has no `timeout`, and the Bash tool's `timeout` is
  ignored under `run_in_background`), nothing checking that a session had started. Hence the
  wrapper. Note that `Reading additional input from stdin...` prints on every run, even with
  stdin closed; the hang signature is that no `session id:` line follows it.
- **The coordinator saw "finished" notices while the foreman's text said "waiting" and only
  relayed the text.** Hence the Waiting rule and `agent-watch.py`, replayed on that session:
  it flags the lost reports and the idle foreman by 01:20, the hung Codex by 09:00 and the
  last lost report by 09:40, and prints nothing on the healthy afternoon.

## The 2026-11-11 rewrite (v4)

Evidence: a review of ten days of sessions in one project (1–11 Nov 2026), plus Doruk's
decisions of 11 Nov.

- **Rules moved from the skill body into two role files loaded by hooks.** In the 4–10 Nov
  session the session-start pointer was shown 18 times and the skill was loaded 0 times.
- **`coordinator-hook.sh` became `main-hook.sh` with no model check.** On Claude Code 2.1.322
  the SessionStart stdin carries no `model`. Doruk starts `claude` with no `--model` and
  `~/.claude/settings.json` says `sonnet`, so the old chain resolved "sonnet" and printed
  nothing, whatever `/model` was switched to afterwards.
- **`foreman-hook.sh` no longer goes silent on any `Role:` line.** The main session opens
  almost every brief with its own role line ("Role: foreman, small scope", "Role:
  designer"), which skipped the injection on 9 of 45 Opus/Fable spawns since 4 Nov,
  including the last six. Only `Role: executor` or `Role: leaf` skips it now.
- **The hook tells main-session spawns from a foreman's helper spawns** by `agent_id` in the
  PreToolUse stdin (present only when a subagent makes the call). Helpers get no foreman
  text.
- **Agents keep their names** (Doruk, 11 Nov): idle notices cost about 2% of the week and he
  wants addressable, continuous agents. The misrouted-report problem (3–4 Nov, 6–7 Nov) is
  handled in the foreman's rules: helpers are spawned in the foreground, so the report is
  the tool result. Checked headless on 2.1.322 for a named and an unnamed helper.
- **A named agent keeps its turn open while Codex runs.** 4 of about 30 runs in the week of
  4 Nov stalled 11–73 minutes, all in named teammates that a background notice did not
  wake. The wrapper is unchanged; the agent waits for its final `CODEX_*` line.
- **`main-hook.sh` is registered per project**, so only projects that orchestrate carry
  the text.
- **Fable effort is set by the hook:** unset becomes `medium`, `xhigh` and `max` become
  `high`. Three long Fable agents made up about 70% of one week's Fable spend.
- **Context limits are soft.** A foreman may run to 300–400k. The main session nudges for a
  handoff past 250k and gives no new tasks past 350k. `depth-gauge.sh --hook` warns it once
  per agent per line. Agents are shown no countdown of their own: Anthropic's Fable 5.2
  guide says a visible token budget raises cost.
- **Intake classes (open / constrained / mechanical) and "Opus drafts, Fable approves" were
  dropped** for routing by size. The class line was shown 0 times in 10 days and the
  draft-approve flow ran 0 times in 31 builds.
- **Gates are run by the foreman.** Foremen already ran 36 of 38 Codex reviews.
