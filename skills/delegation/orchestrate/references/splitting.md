# Splitting big work

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

Moved unchanged from `SKILL.md` v3 on 2026-11-11. "The fresh-agent size above" was about 150k tokens of reading plus writing.
