---
name: prove-it
description: Use when about to write or plan tests for a feature you just built or are building, or about to declare such a feature done. Exercises the feature through its real entry point and leaves a rerunnable check plus evidence.
user_invocable: false
---

# Prove it — done means exercised, with evidence

A feature counts as done when it has run through its real entry point (the UI, CLI, API, or
the skill itself, not a mock of it) and left something repeatable behind. The repo's own test
conventions win over anything here.

## Pick the check

- Complex or integrated feature: an end-to-end check through the entry point. Launching the
  app is your problem to solve; the bundled `run` skill knows common patterns if it is
  installed, but nothing here needs it.
- Genuinely standalone logic (parsers, math, state machines): isolated tests. List the ways
  it can fail before writing any test code; a test written afterwards that restates the
  implementation proves nothing.

## Leave the artifact

1. A script or command that reruns the check, saved where the repo keeps such things
   (its test dir, `scripts/`, or a Makefile/justfile target). One-off shell history does
   not count.
2. The evidence from running it: captured output, a screenshot, or a recording, stored
   next to the script or in the feature's scratch folder.

If the check fails, fix the feature and rerun; if it cannot be exercised end to end, say why
and what was proven instead.

Done: the check passed through the real entry point, and the reply gives the user the artifact
path and the exact rerun command.
