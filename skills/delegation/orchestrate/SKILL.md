---
name: orchestrate
description: Use when running a multi-step build where you delegate every unit of work to
  model-tiered subagents instead of coding yourself. Triggers on "orchestrate this", "run
  this end to end with agents", "delegate with model tiers", or any task where you are the
  orchestrator spawning fable/opus/sonnet subagents and want to know which model goes where.
user_invocable: true
metadata:
  author: doruktarhan
  version: "1.0.0"
  domain: orchestration
  triggers: orchestrate this, run this end to end with agents, delegate with model tiers
  role: reference
  scope: model-tiering
  output-format: terminal
---

# Orchestrate — which agent when

You are the orchestrator. You plan, write the subagent prompts, wire the hand-offs, and
merge. You do **not** write the feature code yourself — every unit of work is delegated.

## Which model, when

| Model      | Use for                                                        | How often          |
|------------|----------------------------------------------------------------|--------------------|
| **Fable**  | The single most complex thing: designing from scratch, or a whole complicated project's plan/spec | ONCE, up front — skip it for simple tasks |
| **Opus**   | Smart work: deep planning, tricky logic, the core build        | as needed          |
| **Sonnet** | All labor: scaffolding, edits, data prep, browser/QA, fixes    | as needed (default)|
| **Codex**  | Read-only review / "what can we improve" (external CLI)         | ONCE, at the end   |

## Hard rules

- **Always set `model` explicitly on every spawn.** Never default-inherit — an orchestrator
  running as Fable that forgets the flag silently spawns everything at Fable cost.
- **Default to Sonnet.** Reach for Opus only when a unit genuinely needs deep reasoning.
- **Fable and Codex are one-shot bookends**, not middle-of-the-run tools: Fable for the
  hardest design/plan at the start (and only if the task is actually complex), Codex for the
  review at the end. Opus + Sonnet carry everything in between.
- **Browser work → Sonnet.**

Adjust on the road — these are defaults, not a contract.
