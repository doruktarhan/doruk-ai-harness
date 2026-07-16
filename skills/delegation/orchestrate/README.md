# orchestrate

A reference skill for running a multi-step build as an orchestrator: every unit of work gets
delegated to a model-tiered subagent instead of being coded directly, and this skill is the
lookup table for which model handles which kind of work.

## What it does

Gives a fixed decision table for spawning subagents: **Fable** for the single most complex
thing up front — designing from scratch, or a whole complicated project's plan/spec — used
once and skipped entirely for simple tasks; **Opus** for smart work like deep planning and
tricky logic; **Sonnet** as the default for all labor (scaffolding, edits, data prep,
browser/QA, fixes); and **Codex** for a one-shot, read-only "what can we improve" review at
the end. It also pins down the two hard rules that keep an orchestrator honest: always set
`model` explicitly on every spawn (never default-inherit, or an orchestrator running as
Fable silently spawns everything at Fable cost), and default to Sonnet, reaching for Opus
only when a unit genuinely needs deep reasoning.

## Why I built it

I kept catching myself, as an orchestrator, either forgetting to set a subagent's model at
all — so it silently inherited whatever tier I was running as — or defaulting everything to
the smartest model out of habit, which is expensive for work that's really just labor. I
wanted one place that says, at a glance, which model a unit of work should get: Fable once
at the start for the hardest design call, Sonnet by default for everything else, Opus only
when a step actually needs it, Codex once at the end for a second opinion. Now spawning a
subagent is a lookup, not a judgment call I re-make every time.

## How to use it

Copy this folder into your skills directory:

```bash
cp -r orchestrate ~/.claude/skills/
```

Then just say what you want built end to end — "orchestrate this", "run this end to end
with agents", "delegate with model tiers" — and the agent plans, writes the subagent
prompts, wires the hand-offs, and merges, using the table above to pick each spawn's model.
It never writes the feature code itself; every unit of work is delegated.
