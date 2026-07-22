---
name: orchestrate
description: Use when running a multi-step build where you delegate every unit of work to
  model-tiered subagents instead of coding yourself. Triggers on "orchestrate this", "run
  this end to end with agents", "delegate with model tiers", "coordinator", "delegate", "agent
  team", or any task where you are the orchestrator spawning fable/opus/sonnet subagents and
  want to know which model goes where.
user_invocable: true
metadata:
  author: doruktarhan
  version: "2.0.0"
  domain: orchestration
  triggers: orchestrate this, run this end to end with agents, delegate with model tiers, coordinator, delegate, agent team
  role: reference
  scope: model-tiering
  output-format: terminal
---

# Orchestrate — roles, classification, model tiers

## Roles (check first)

Three roles, keyed by ROLE, not model name:

- **coordinator** — designs, classifies, delegates, reviews, lands. Never does bulk labor itself.
- **executor** — a leaf. Does the work order itself, NEVER spawns agents, reports back when
  blocked instead of improvising.
- **foreman** — OPT-IN. Owns one complete build; may spawn Sonnet leaf executors and run its
  own mid-build Codex review iterations. May NOT spawn another foreman — one level deep, ever.

If your prompt starts with `ROLE: EXECUTOR` or `ROLE: FOREMAN`, or you were spawned by
another agent, adopt that role and its constraints. As coordinator, start every spawn
prompt with the role line. Foreman rights are granted explicitly in the work order,
including a rough size budget. Default for all spawns is executor (no spawn rights) —
foreman is rare; reach for it only when a whole multi-day build is handed down at once.

## Intake classification

One classification per task, decided once, up front: **open / constrained / mechanical**.

- **open** — design space wide, wrong shape expensive (new subsystem, frozen API contracts,
  security/concurrency). Fable designs directly; Codex gates: spec review + final diff review.
- **constrained** — codebase/pattern dictates most of the shape. Opus drafts the design,
  Fable (coordinator) reviews/approves it; Codex gate: final diff review only.
- **mechanical** — rename/bump/lint-fix/test-add/apply-a-specified-fix. No designer, no Codex
  gate by default.
- **Escalation**: if a mechanical task's diff outgrows its classification (touches shared or
  risk-bearing code — auth, money, data writes, concurrency, migrations — or the executor
  reports surprises/failed attempts), upgrade to a Sol diff review before landing.
- Surface the classification to Doruk as a one-liner at task start ("treating this as:
  constrained — Opus designs, diff gate only") so he can veto cheaply. He may also trigger
  any review manually at any time.

## Which model, when

| Role/tier  | Model                              | Notes |
|------------|-------------------------------------|-------|
| Coordinator| The resident session model         | Fable when available; same rules apply unchanged if the resident is Opus/Sonnet on a throttled week — rules are role-keyed on purpose. |
| Design     | Fable (open) / Opus (constrained)  | Opus drafts constrained designs; Fable reviews the draft — reviewing costs ~5% of producing. |
| Executors  | Sonnet, always                     | Own roomier quota pool. Never Haiku — rework costs more than the savings. |
| Reviewer   | Codex Sol, always                  | Never a smaller Codex tier for reviews — a weak reviewer is false confidence. Effort dial instead: medium default, high for very complex/open work; a foreman's own mid-build reviews may run lower effort (converging, not certifying). Coordinator's final gate stays Sol at medium+. |

Role names describe **spawn rights**, not model tier: a constrained-flow design draft is an
executor (no spawn rights) that happens to run on Opus per the Design row above — "Sonnet,
always" is about labor/implementation executors specifically, not every executor spawn.

**Hard rule, unchanged from v1:** always set `model` explicitly on every spawn. Never
default-inherit — a coordinator running as Fable that forgets the flag silently spawns
everything at Fable cost.

## Delegation heuristics

- Delegate by expected context-tonnage, not task importance: needing >~2–3 files read, or not
  knowing where the answer lives → fan out Sonnet scouts. A targeted lookup you already know
  the location of → do it directly (delegation overhead costs more than the lookup).
- Exception the coordinator keeps: code it is making an architectural bet on — read the
  load-bearing files yourself; secondhand summaries lose exactly what the design hinges on.
- Task-size flip: if the new work itself looks >~150k tokens of reading+writing, that alone
  says "fresh dedicated agent," regardless of any existing agent's state.
- Brief big work orders BY REFERENCE (a frozen spec file in the feature folder: "Read FIRST:
  `<path>`"), not by inline context-dump. Brief small work fully inline.
- Executor prompts are self-contained — context, constraints, expected output format.
  Subagents don't see the conversation. Review their output before accepting it.

## Persistent agents

- Default: keep a deep agent ALIVE and message it (SendMessage) for follow-ups, revisions,
  and related next steps, rather than spawning fresh. A 476k-token builder stayed sharp on a
  1M-token window — depth alone isn't a reason to retire an agent.
- Fresh spawn only for: genuinely unrelated work, or a degraded/off-the-rails agent.
- The one named mistake to avoid: re-spawning fresh for a REVISION of work an existing agent
  already did — that re-buys context the team already paid for.
- "A deep agent is a good witness and a bad builder": keep asking it questions; stop giving it
  new projects. Depth is judged by what you fed it, not metered automatically. Escape hatch
  when unsure: the last `"usage"` object in the agent's transcript
  (`~/.claude/projects/<proj>/<session>/subagents/agent-*.jsonl`) — live context =
  input_tokens + cache_read_input_tokens + cache_creation_input_tokens. Thresholds are
  window-relative (~150k marks "deep" on a 1M window; scouts naturally live and die under
  ~110k).
- Forced retirement only (context pressure, cost, or degradation): the retiring agent's LAST
  task is a successor note — what it built, decisions made, file map, gotchas, dead ends. The
  coordinator's own record is too distilled to reconstruct that. No handoff files otherwise;
  it's hub-and-spoke — leaf executors never communicate laterally; communication flows
  coordinator → (foreman) → leaf, at most one delegated level.

## Review gates

- Gates fire on frozen artifacts only (a spec, a final diff), never on intermediate states.
- **open** → Sol adversarial spec review BEFORE implementation + Sol diff review before landing.
- **constrained** → Sol diff review before landing. **mechanical** → none by default (see
  escalation rule above).
- The coordinator owns triggering each gate, evaluating the review report, and the land
  decision — that ownership is never delegated, never skipped; Codex Sol performs the
  artifact reviews themselves.
- Current mechanism: existing codex skills / codex CLI. Migration to
  `openai/codex-plugin-cc` (`/codex:review`, `/codex:adversarial-review`) is a future step —
  gate language above is written mechanism-neutral ("run a Sol diff review") so that migration
  only swaps the how.

## Sessions that are NOT builds

In discuss/research sessions the only rule that always applies: delegate read-heavy
exploration to Sonnet scouts instead of reading broadly yourself. Full orchestration
(roles, classification, gates) activates once hands-on work starts.

## Kept from v1

- Default to Sonnet for labor; browser/QA work → Sonnet.
- These are defaults, not a contract — adjust on the road.
