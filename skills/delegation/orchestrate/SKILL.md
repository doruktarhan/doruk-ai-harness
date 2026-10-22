---
name: orchestrate
description: Use when delegating every unit of a multi-step build to model-tiered Claude
  subagents instead of coding it yourself. Triggers on "orchestrate this", "run this end to
  end with agents", "delegate with model tiers", or picking which model (fable/opus/sonnet)
  a spawn should get.
user_invocable: true
metadata:
  author: doruktarhan
  version: "3.0.0"
  domain: orchestration
  triggers: orchestrate this, run this end to end with agents, delegate with model tiers
  role: reference
  scope: model-tiering
  output-format: terminal
---

# Orchestrate — roles, classification, model tiers

Evidence behind the thresholds, and incident history: [`references/rationale.md`](references/rationale.md).

## Roles

Keyed by ROLE, not model tier; a role names spawn rights only.

| Role | Rights |
|------|--------|
| coordinator | Designs, classifies, delegates, reviews, lands. No bulk labor. |
| executor | Leaf. Does the order, spawns nothing, reports back when blocked rather than improvising. |
| foreman | Default for a Fable/Opus spawn, or granted in the order with a size budget. Owns one build, may spawn Sonnet leaves and run mid-build Codex reviews, cannot spawn another foreman. Delegates exploration and labor to Sonnet even in review, design and spec jobs; keeps the verdict, design, spec and final page itself. |

Spawns default by tier: Fable/Opus spawns are foremen, Sonnet spawns executors.
`foreman-hook.sh` (PreToolUse on Agent, see `HOOK-INSTALL.md`) prepends the foreman line to a
Fable/Opus prompt that opens with no role line. Open a spawn prompt with its role line to
override; adopt the role your own prompt names.

## Intake classification

One per task, up front, surfaced to Doruk as a one-liner ("treating this as: constrained")
so he can veto cheaply. He may also trigger any review manually.

| Class | Meaning | Designer | Gates |
|-------|---------|----------|-------|
| open | Wide design space, wrong shape expensive: new subsystem, frozen API contract, security, concurrency. | Fable directly | Adversarial spec review, then diff review before landing |
| constrained | Codebase or pattern dictates the shape. | Opus drafts, Fable approves | Diff review before landing |
| mechanical | Rename, bump, lint-fix, test-add, apply-a-specified-fix. | none | none by default |

Escalation: a mechanical diff touching risk-bearing code (auth, money, data writes,
concurrency, migrations), or drawing surprises and failed attempts from the executor, gets a
Sol diff review before landing, Astra if it turned out architectural or backend-critical.

## Which model

| Tier | Model | Notes |
|------|-------|-------|
| Coordinator | Resident session model | Fable when available; rules are role-keyed, so they hold on Opus or Sonnet. |
| Design | Fable (open) / Opus (constrained) | Fable reviews Opus's draft. |
| Labor executor | Codex Luna at max effort (background) / Sonnet (interactive) | Sonnet for labor you will iterate on mid-flight, and browser/QA. Never Haiku. |
| Reviewer | Codex Sol (routine) / Codex Astra (heavyweight) | Never Luna or a smaller tier. Sol at medium, high for very complex or open work; the coordinator's final gate never below medium, a foreman's mid-build reviews may go lower. Astra at medium, high only for the hardest open specs, on big architectural changes, backend builds (services, data layers, migrations, auth, concurrency), and complex specs. |

A constrained design draft is an executor running on Opus: "Sonnet always" covers labor
executors, not every spawn. Set `model` explicitly on every spawn; never default-inherit.

## Codex

Labor is `gpt-6-luna` at max effort in `workspace-write`; reviews are `gpt-6-sol` or
`gpt-6-astra` at medium in `read-only`. Pin `-m` on every `codex exec`, or it takes whatever
`~/.codex/config.toml` was last set to. Luna executors are Bash processes, so the
persistent-agent rules below do not reach them and `codex exec resume` is weak — route
iterative work to Sonnet. Invocation lines: `references/rationale.md`.

Every `codex exec` runs through `~/.claude/skills/codex/scripts/codex-run.sh` (stdin closed,
wall-clock cap, killed if no session id within 120 s), usually as a background Bash. macOS
has no `timeout`, and the Bash tool's `timeout` is ignored under `run_in_background`. A brief
that orders a Codex gate names the wrapper, not a bare `codex exec`.

## Waiting

Spawn helpers without `name`. With agent teams on, a named spawn becomes a session teammate
whose report and done notice go to the coordinator's team inbox, which nobody reads. An
unnamed helper wakes you when it finishes, and you message it later by the `agentId` its
spawn result returned.

End a turn to wait only when something will wake you: an unnamed helper you spawned, or a
background Bash you launched. To wait on anything else (a commit, a file, an agent you did
not spawn), launch a background waiter with a deadline first, e.g.
`for i in $(seq 1 60); do git -C <wt> log --oneline -5 | grep -q '<msg>' && break; sleep 30; done`
as a background Bash. The waiter counts as a waker: its exit wakes you whether the thing
landed or the deadline passed, and on a passed deadline you report upward rather than
re-arm. On waking, read the result on disk (git log, files) before acting on a summary.

Coordinator: a foreman stop notice with summary "finished" whose text says it is waiting
means nothing will wake it. Check its awaited items on disk and message it what landed.
During an overnight build, schedule `agent-watch.py` (this folder) every 20 minutes and act
on each line it prints: `references/watchdog.md`.

## Delegation

- Delegate by context tonnage, not importance: over ~2–3 files to read, or not knowing where
  the answer lives, means Sonnet scouts. A lookup you can already locate, do direct.
- Read yourself: code you are making an architectural bet on, plus instructions, skills, and
  specs you will act on. Secondhand summaries lose what the design hinges on.
- Fable writes instructions for agents: skills, CLAUDE.md/AGENTS.md, hook text, task-prompt
  templates. Opus and Sonnet audit, research, and report; Fable distills their reports into
  the text, following `lean-instructions`. Probe the real system yourself, test with one
  fresh Sonnet run allowed to read only the skill file, fix what it got wrong. If the
  coordinator is not Fable, spawn a Fable agent for this step.
- New work over ~150k tokens of reading plus writing gets a fresh dedicated agent, whatever
  any existing agent's state.
- Brief big orders by reference to a frozen spec ("Read FIRST: `<path>`"), small work inline.
  Prompts are self-contained: context, constraints, output format. Review output before
  accepting it.

## Splitting big work

When an order would have one agent read widely before it writes (big design, big build,
broad review, multi-question research), you may split it rather than delegate it whole.
This is your call, made per order.

- Signals to split: the brief would read "here is everything, design it"; the work has
  seams you can name; a review covers separable sections; a research brief holds several
  independent questions.
- Signals to leave whole: it fits one agent under the fresh-agent size above; the pieces
  cannot be specified without each other; you cannot name the pieces yet, so scout first.
- Start from a short global plan: named pieces, exact seams (interfaces, invariants,
  dependency order). Each piece gets its own agent, briefed with only its sections and
  `file:line` anchors. Research scouts get one question each.
- You hold the global picture and leave the bulk piece inputs to the agents. One or two
  agents may check cross-piece consistency, reading only the assembled document and looking
  only at the seams (names, units, clocks, shared state).

## Persistent agents

Route by a 2×2: follow-ups, revisions, and questions to the warm agent, messaged by the
`agentId` its spawn returned rather than respawned; new substantial work to a fresh agent,
however convenient the warm one looks.
Otherwise spawn fresh only for unrelated work or a degraded agent.

- Depth is measured, never guessed: run `depth-gauge.sh <session-dir>` (this folder) before
  reusing an agent for new work. Self-reports are hints, in absolute tokens plus assumed
  window ("≈ 100k of ~200k"), never a percentage.
- Thresholds are window-relative: ~50–60% of the real window means no new tasks, so ~100–120k
  on a 200k window. Confirm the window per environment; never assume 1M.
- A deep agent is a good witness and a bad builder: keep asking questions, stop giving projects.
- Forced retirement only (context pressure, cost, degradation), and its last task is a
  successor note: what it built, decisions, file map, gotchas, dead ends. No other handoff
  files — it is hub-and-spoke, coordinator → (foreman) → leaf, one delegated level, no
  lateral talk.

## Review gates

Gates fire on frozen artifacts only, a spec or a final diff, never intermediate states. The
class table says which gate, the reviewer row says Sol or Astra. Codex reviews; the
coordinator owns triggering each gate, judging the report, and landing. Mechanism today is
the codex skills and CLI, kept mechanism-neutral here.

In discuss and research sessions, roles, classification, and gates stay off until hands-on
work starts. All of the above are defaults, not a contract.

Done when every delegated unit has returned and been verified, its gate cleared, the work
landed, and a summary reported to Doruk.
