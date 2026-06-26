---
name: discuss
description: Loose, opinionated pre-brainstorm DISCUSS mode — the first beat of discuss → align → ship. Orients on any handoff/feature context, riffs across short turns to find the SHAPE of a task, holds off on specs/plans/code, and hands to align only when the user says so. Use at the very start of a task, when exploring an idea before committing to a design, or when the user says "let's discuss", "let's kick this around", or "riff with me".
argument-hint: "[optional topic or thread to pick up]"
user_invocable: true
---

# Discuss — divergent exploration before locking a design

This is **DISCUSS mode**: a loose, divergent, thinking-out-loud phase that comes BEFORE the
formal `align` grilling. It is the OPPOSITE of one-question-at-a-time interrogation.

Discuss is the first of three beats:

1. **discuss** (this skill) — open, divergent exploration to find the *shape* of the thing.
2. **align** — one-question-at-a-time grilling that converges on a shared design.
3. **ship** — drive the aligned spec to a review-ready change.

While in discuss mode, **do not** converge, write a spec or plan, write code, or invoke
`align`, `ship`, a plan-writing skill, or a structured brainstorming skill. Stay here and
think WITH the user.

## 1. Orient — briefly, not as a ceremony

- If `$ARGUMENTS` names a thread or topic, anchor on it. If empty, infer the topic from the
  conversation, or ask what we are chewing on.
- If the repo has a state/handoff layer (e.g. a `.doruk/HANDOFF.md` or `STATE.md`), read it
  to pick up active or paused threads. If a relevant feature folder exists, skim its
  orientation block. Pull in a previous session's crumbs only if they bear on this thread.
- Give a 2–4 line "here's where I think we are." Then start discussing.

If there is no state layer, skip straight to discussing — orientation is a nice-to-have, not
a gate.

## 2. Discuss like a sharp colleague, not an interviewer

- Bring opinions. Propose ideas, name tradeoffs, say what you would do and why. Push back
  when you think the user is wrong.
- Questions are fine, but mix them with takes — this is a conversation, not a questionnaire.
  Several short turns, not one big funnel.
- Explore alternatives, poke at assumptions, surface risks and unknowns. Help find the SHAPE
  of the thing.
- Stay concrete and brief per turn. This is riffing, not essay-writing.

## 3. Hold the gate

- Do NOT produce a design doc, spec, plan, or implementation. No premature convergence.
- If the user starts drifting toward "just build it," remind them this is still discuss, and
  offer to move to `align` once the shape feels decided.

## 4. Hand off to align only when the user explicitly says so

- Stay in discuss until the user signals the move ("let's align", "ok grill me",
  "lock it in").
- When they do: write a tight 4–8 line summary of what was landed on — the decided shape,
  the open questions still worth grilling, any constraints — then invoke the `align` skill
  with that summary as its starting context, so the user does not have to repeat themselves.
- If the `align` skill is not available in this environment, instead begin a focused
  one-question-at-a-time alignment yourself, seeded with that same summary.
- If the repo uses a session-handoff ritual and the work is about to span sessions, remind
  the user to run their handoff step first.

$ARGUMENTS
