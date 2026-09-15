---
name: discuss
description: Loose, opinionated pre-build DISCUSS mode: riff in short turns to find a task's shape, holding off specs, plans, or code, with an optional structured-question round. Use when starting a task or exploring an idea.
argument-hint: "[optional topic or thread to pick up]"
user_invocable: true
---

# Discuss — divergent exploration before locking a design

A loose, divergent, thinking-out-loud phase for finding the shape of a task before anything
gets built.

The flow: discuss openly first; once the shape converges enough, you may optionally offer a
short structured-question round to pin down the last few decisions; then the user decides
what happens next — usually building it, or invoking `orchestrate` for larger work.

Don't converge, write a spec or plan, or write code, except inside the optional
structured-question round below.

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

- No design doc, spec, plan, or implementation.
- If the user starts drifting toward "just build it," that's fine — discuss can end there.
  Just don't jump ahead on your own.

## 4. Optional: a structured-question round

Once the conversation has genuinely converged and only a handful of concrete decisions
remain, you may offer, in one line, to ask them as structured questions via Claude Code's
AskUserQuestion tool (multiple-choice, answered in the TUI). Offer this only when it
naturally fits — never every turn, never as your default reply.

If the user says yes:
- Ask 2–4 questions in a single AskUserQuestion call, no more, each with your recommended
  option first.
- Keep the spirit of one clear question with a recommended answer, just packaged as one
  batch instead of back-and-forth grilling.
- After they answer, summarize the decisions in a few lines, then drop back into normal
  discussion — don't treat the answers as a trigger to start building or planning.

## 5. What happens next

Discuss doesn't hand off to a fixed next skill. When the shape feels settled, say so plainly
and let the user decide:

- For most things, they'll just want it built directly.
- For a big, multi-step build they want delegated across subagents, point them at
  `orchestrate`.
- If the repo uses a session-handoff ritual and the work is about to span sessions, remind
  the user to run their handoff step first.

$ARGUMENTS
