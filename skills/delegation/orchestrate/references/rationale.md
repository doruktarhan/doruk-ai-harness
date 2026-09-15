# orchestrate — rationale and incident log

Background for the rules in `SKILL.md`. Not needed in the hot path; read when a rule looks
arbitrary or when you are tempted to change one.

## Why models are tiered this way

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
explicitly.

```bash
# labor  → codex-task-delegator
codex exec -m gpt-5.6-luna -c model_reasoning_effort="max" --sandbox workspace-write "<order>" < /dev/null
# review → codex-feedback-planning
codex exec -m gpt-5.6-sol  -c model_reasoning_effort="medium" --sandbox read-only "<order>" < /dev/null
# heavyweight review (codex-cli 0.153.4+)
codex exec -m gpt-6-astra  -c model_reasoning_effort="medium" --sandbox read-only "<order>" < /dev/null
```

Luna executors are Bash processes, not Claude subagents: no `SendMessage`, no
`depth-gauge.sh`, no `ROLE:` enforcement, and the persistent-agent rules do not apply to
them. Launch with `run_in_background` and collect the output file.
