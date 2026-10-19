# align — pin down every design decision before you build

The convergent beat of my workflow: once an idea has a rough shape (usually out of
`/discuss`), `/align` interviews me until the agent and I hold one design, then I build it
directly or hand it to `orchestrate`.

The method is [Matt Pocock's `grilling` skill](https://github.com/mattpocock/skills)
(MIT): the plan as a design tree, a frontier of askable decisions, every question with a
recommended answer. What I added is a pace setting, a depth knob, a brainstorm-first turn
for vague ideas, and a `.doruk/` ending. See [`PROVENANCE.md`](../../../PROVENANCE.md).

## What it does

- **Brainstorms first if the idea is vague** — 1–2 turns of opinions, alternatives and
  pushback before any question. Skipped when the idea arrives sharp.
- **Walks a design tree** — every decision branches into the decisions that hang off it. The
  *frontier* is whatever can be asked now without guessing at an answer not yet heard; each
  reply reshapes the tree. Facts (what the code does, what a tool supports) are the agent's
  job, looked up or delegated to a sub-agent; decisions are mine.
- **Every question carries a recommended answer**, worded so "yes" accepts it. Most turns I
  just say yes and push back only where it matters.
- **Two paces, chosen once up front** — *one by one*: a single question per turn, each
  carrying its own 1–2 lines of context and one line on why it's being asked, so I never
  scroll up to find what "Q2" meant. *Bulk rounds*: the whole frontier in one numbered round
  (Pocock's ❓/➡️ format). I can switch mid-session. Clear multiple-choice questions can come
  through Claude Code's TUI picker instead of text.
- **Depth scales soft↔hard** — soft asks only the decisions that really matter, then
  converges; hard walks every branch. Taken from my wording, else judged from the task.
- **Ends with decisions on disk** — a few-line summary, an offer to write it into the
  feature's `handoff.md` (or `roadmap.md`), then I pick what's next.

## Why I built it

The failure mode: an agent nods along, then builds the wrong thing, because a dozen small
decisions got made silently in the gaps I never spoke to. Pocock's grilling fixes that by
making the decision tree explicit. What it didn't fit was how I actually answer: in a
back-and-forth I want each question to be digestible on its own, with its context and the
reason it's asked, and I don't want to scroll back to earlier rounds. So the pace setting
is the main thing this skill adds, plus the soft↔hard knob so trivial work isn't exhausting.

## How to use it

1. Copy this `align/` folder into `~/.claude/skills/` (or your project's `.claude/skills/`),
   or install the whole harness via `/plugin install`.
2. Run `/align <idea>`, or say "lets align", "grill me", "stress-test this plan". Add `soft`
   or `hard` to force the depth.
3. Pick a pace when asked. Answer; push back where you disagree.
4. When it summarizes the agreed design, say yes to writing it into `.doruk/`, then build or
   run `orchestrate`.

It pairs with `/discuss` (looser exploration before it) but stands alone as a "grill me on
this plan" tool any time.
