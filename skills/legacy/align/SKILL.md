---
name: align
description: "Use when you want to think an idea through before building — a one-question-at-a-time grilling that converges on a shared design. Run before /ship. Triggers on /align, 'lets align', 'align on this', 'grill me on this'. Depth scales soft↔hard."
argument-hint: "[soft | hard] <idea>   (or just describe it — I'll judge the depth)"
user_invocable: true
---

# /align — Get aligned before building

The middle beat of the workflow: turn an idea into a design we both agree on by
interviewing the user one question at a time. Run after loose exploration (`/discuss`) and
before the build (`/ship`). End by offering to run `/ship`.

## How to ask
- One short question at a time, each with your recommended answer.
- If the codebase can answer it, go look instead of asking.
- Plain language, no walls of text.
- Don't move on while an answer is still vague — pin it down first.

## Depth — soft vs hard
Take it from the user's wording; otherwise judge it from the task:
- **Soft** — a few questions on the genuinely open points, then converge. (Small or clear
  work, or the user says "soft" / "quick align".)
- **Hard** — relentless: walk every branch, resolve dependencies one by one, don't let
  vague answers slide. (Big / ambiguous / architectural work, or the user says "hard" /
  "grill me".)

Unsure? Start soft, go deeper only where answers stay fuzzy.

## When aligned
Summarize the agreed design in a few lines, then ask: "Run `/ship` to take this to a PR?"
