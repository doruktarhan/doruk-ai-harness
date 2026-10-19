---
name: align
description: "Use before building, once an idea has a rough shape, to pin down every open design decision with the user. Triggers on /align, 'lets align', 'align on this', 'grill me', 'grill this', 'stress-test this plan'."
argument-hint: "[soft | hard] <idea>   (or just describe it — I'll judge the depth)"
user_invocable: true
---

# /align — design-alignment interview before building

Interview the user until the two of you hold one design. The method is Matt Pocock's
`grilling` skill (design tree, frontier, recommended answers) with a pace setting on top.

## Brainstorm first if the idea is still vague

Spend 1–2 turns with opinions, alternatives and pushback before any questions. Skip this
when the idea arrives sharp.

## The design tree

Map the plan as a tree of decisions: each decision branches into the ones that hang off it.
The **frontier** is every decision whose prerequisites are settled, so it can be asked now
without guessing at an answer you haven't heard. Each reply reshapes the tree; recompute the
frontier after every answer. A question that depends on one still open waits.

- Every question carries your recommended answer, worded so "yes" accepts it.
- Facts are yours: look them up in the repo or tools. Dispatch a sub-agent for a bigger
  lookup and keep asking the questions that don't depend on it. Never ask the user for
  something you can find yourself. Decisions are the user's: put each to them and wait.
- A vague answer gets pinned down before you move on.

## Depth

Take it from the user's wording ("soft", "quick", "hard", "grill me"); otherwise judge from
the task. **Soft:** only the decisions that really matter, then converge. **Hard:** walk
every branch. Unsure: start soft, go deeper where answers stay fuzzy.

## Pace: ask once, before the first question

After any brainstorm and right before the first design question, unless the user already
said, ask with AskUserQuestion which they want (mention they can switch later):

- **One by one** — one frontier question per turn, the one that unblocks the most first; fully self-contained: 1–2 lines of plain context
  (what this decision is about), one line on why it's asked (what it unblocks, or what goes
  wrong if it stays open), then the question and the recommended answer. Never point back
  ("as above", "Q2 earlier", "the option we discussed"); restate the needed bit in one line.
- **Bulk rounds** — the whole frontier in one numbered round, in Pocock's format:

  ```
  ❓ **Q1** - **<title>**: <context and why in 1–2 lines, then the question>

  ➡️ <recommended answer>
  ```

  Each question still makes sense on its own. Numbering restarts at Q1 each round.

The user can switch modes mid-session. A tiny progress line per turn ("3 settled, ~4 open")
is welcome.

When a single question (one by one) or a round of up to 4 simple choices (bulk) has clear
discrete options, AskUserQuestion may replace text; the context and why go in the question
text or the option descriptions.

## Ending

Done when the frontier is empty and the user confirms shared understanding; don't build
before that. Then summarize the decisions in a few lines. If the repo has a `.doruk/` feature
folder for this work, offer to write them into its `handoff.md` (or `roadmap.md` if one
exists). Let the user pick what's next: build directly, or `orchestrate` for big work.

$ARGUMENTS
