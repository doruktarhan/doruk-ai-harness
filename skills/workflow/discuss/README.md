# discuss — divergent exploration before you lock a design

The first beat of my `discuss → align → ship` workflow. A loose, opinionated mode where the
agent riffs WITH me across short turns to find the *shape* of a task, before any spec, plan,
or code exists.

## What it does

`/discuss` puts the agent into a deliberately divergent mode:

- **Orients lightly** — if the repo has a state/handoff layer it reads the active threads and
  gives me a 2–4 line "here's where we are," then gets out of the way. No ceremony.
- **Talks like a colleague, not an interviewer** — it brings opinions, names tradeoffs, pokes
  at my assumptions, and pushes back. Questions are mixed with takes across several short
  turns, not fired one at a time.
- **Holds the gate** — it refuses to write a spec, plan, or code while we are still exploring.
  If I drift toward "just build it," it reminds me we are still in discuss.
- **Hands off cleanly** — only when I explicitly say so, it summarizes what we landed on in
  4–8 lines and passes that into the `align` skill so I never repeat myself.

## Why I built it

I noticed that the moment I describe a task, most agents lunge straight at a plan or at code.
That is the worst time to converge: I have not figured out what I actually want yet, and the
agent locks onto the first interpretation it can defend. Premature convergence quietly bakes
in the wrong shape, and everything downstream inherits it.

So I split the front of my workflow into three explicit beats. **discuss** is the divergent
one: its whole job is to stay open and find the shape with me. **align** is where I get
grilled one question at a time until a design is pinned down. **ship** drives that pinned
design to a review-ready change with quality gates. Keeping these separate means the
divergent thinking actually happens instead of getting steamrolled by an eager planner, and
the convergent thinking happens deliberately rather than by accident.

The handoff is the part I care most about. When the shape feels decided, discuss does not
just stop — it distills what we agreed into a short summary and feeds it straight into
`align`, so the grilling phase starts already knowing the context.

## How to use it

1. Copy this `discuss/` folder into `~/.claude/skills/` (or your project's
   `.claude/skills/`).
2. At the start of a task, run `/discuss` — optionally with a topic, e.g.
   `/discuss the caching layer for the import job`.
3. Riff. Disagree with it, let it disagree with you, chase alternatives.
4. When the shape feels right, say "let's align" (or "grill me", "lock it in"). It will
   summarize and hand off to the `align` skill.

It pairs with the `align` and `ship` skills in this collection, but it stands alone: if
`align` is not installed, discuss falls back to running a focused one-question-at-a-time
alignment itself. It also works with or without a `.doruk/`-style state layer — orientation
is a bonus, not a requirement.
