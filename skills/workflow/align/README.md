# align — converge on a shared design before you build

A drop-in skill for the middle beat of my build workflow: `discuss → align → ship`. Once
an idea is roughly shaped, `/align` interviews me one question at a time until the design is
something the agent and I both actually agree on, then hands off to `/ship`.

## What it does

`/align` runs a one-question-at-a-time grilling that converges on a design:

- **One short question per turn**, each carrying the agent's recommended answer, so I can
  just say "yes" most of the time and only push back where it matters.
- **Self-serve from the code** — if the codebase can answer a question, the agent goes and
  reads it instead of asking me.
- **Depth scales soft↔hard** — soft is a few questions on the genuinely open points for
  small or clear work; hard is relentless, walking every branch and refusing to let a vague
  answer slide, for big or architectural work. The agent picks from my wording or the task,
  and when unsure starts soft and goes deeper only where answers stay fuzzy.
- **Ends with a handoff** — once aligned, it summarizes the agreed design in a few lines and
  offers to run `/ship`.

## Why I built it

The failure mode I kept hitting was an agent that nods along, then builds the wrong thing.
I'd describe an idea, it would "understand", and twenty minutes later the diff was off
because a dozen small decisions got made silently in the gaps I never spoke to.

So I made the decisions explicit and serialized. Forcing one question at a time, each with a
recommended answer, turns the design into a decision tree we walk together instead of a wall
of assumptions. The soft↔hard knob keeps it from being exhausting on trivial work while
staying ruthless on the architectural calls that are expensive to get wrong. By the time it
hands to `/ship`, there's a design we both signed off on, which is what makes the autonomous
build downstream safe to let run.

It's the bridge between divergent thinking (`/discuss`) and execution (`/ship`): discuss
opens the space, align closes it to one agreed design, ship drives that to a PR.

## How to use it

1. Copy this `align/` folder into `~/.claude/skills/` (or your project's
   `.claude/skills/`).
2. Run `/align <idea>` when you want to pin a design down before building. Add `soft` or
   `hard` to force the depth, or just describe the idea and let it judge.
3. Answer the questions; push back on the recommended answers where you disagree.
4. When it summarizes the agreed design, run `/ship` to take it to a review-ready PR.

It pairs with `/discuss` (the looser exploration that runs before it) and `/ship` (the build
loop that runs after) — but it stands alone fine as a "grill me on this plan" tool any time
you want a design stress-tested before committing.
