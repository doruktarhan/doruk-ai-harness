# demo-app — a worked example of the harness

`todo-api` is a **fictional, throwaway project** that exists only to show the
`.doruk/` handoff harness *in motion*. There is no real product here. Everything
in this folder is synthetic: a generic todo REST API, mid-flight, with a real
working `.doruk/` so a visitor can SEE the system working instead of reading
about it in the abstract.

## What to look at

The interesting part is `.doruk/`, not the app:

```
demo-app/
├── README.md                 ← you are here
├── src/                      ← tiny fictional todo-api (just enough to be believable)
└── .doruk/
    ├── STATE.md              ← the landscape: every feature, its status + next move
    ├── MEMORY.md             ← index of durable project memory
    ├── memory/               ← frontmatter'd memory files (decisions that outlive a session)
    └── features/
        └── 01-tag-filtering/ ← a real mid-flight feature
            ├── feature.md    ← the durable record (what it is, decisions + WHY)
            ├── handoff.md    ← the live baton: status + exact next move
            └── scratch/      ← in-flight working notes (gets distilled on ship)
```

## How to read it (suggested order)

1. **`.doruk/STATE.md`** — start here. One table = the whole project at a glance:
   what's done, what's active, and the single next move for each feature.
2. **`.doruk/features/01-tag-filtering/handoff.md`** — the baton. If you picked up
   this project cold, this one file tells you exactly where to resume.
3. **`.doruk/features/01-tag-filtering/feature.md`** — the durable record. Decisions
   and the WHY behind them, written so a future agent doesn't re-litigate them.
4. **`.doruk/MEMORY.md` + `.doruk/memory/`** — cross-feature knowledge that any
   session should load: stack conventions, a load-bearing constraint, a gotcha.

## The point

A session ends. The next session (you, a teammate, or an agent days later) reads
`.doruk/` and rebuilds the full mental model in under a minute, no archaeology
through chat logs. STATE = the map, `handoff.md` = the baton, `feature.md` = the
record, `memory/` = what must never be re-learned the hard way.

*This is demo data. `todo-api` ships nothing.*
