# MEMORY — todo-api (demo)
> Updated: 2026-06-26

Durable, cross-feature knowledge. Anything here is true across sessions and
should be loaded before starting work. One entry per file in `memory/`; each
file carries frontmatter so it can be indexed and filtered. Feature-specific
detail stays in the feature folder, not here.

| file | scope | one-line |
|------|-------|----------|
| `memory/stack-and-conventions.md` | project-wide | Flask single-file app, pytest, in-memory store; naming + run commands |
| `memory/in-memory-store-constraint.md` | data layer | the store is a process-local list — load-bearing constraint, not a TODO |
| `memory/query-param-normalization.md` | api / gotcha | always normalize user-supplied query params (`.strip().lower()`) on both sides |

## How to use
- New session: skim this table, open whichever entries touch your task.
- New durable fact (a decision that outlives one feature, a constraint, a gotcha
  someone will trip on again): add a frontmatter'd file to `memory/` and a row here.
- Keep it small. If it's only true for one feature, it belongs in that
  `feature.md`, not in memory.

*Demo data.*
