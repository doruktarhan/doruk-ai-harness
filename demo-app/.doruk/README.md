# .doruk — handoff + state for todo-api (demo data)

State and handoff for this repo, managed by the `/handoff` skill. Read
`STATE.md` first, then the relevant feature's `handoff.md`.

Layout convention used here:

- **`STATE.md`** — the landscape. One table: every feature, its status, and the
  single next move. The map you read first.
- **`MEMORY.md` + `memory/`** — durable, cross-feature knowledge. Frontmatter'd
  files any session should load (stack conventions, load-bearing constraints,
  gotchas that must not be re-learned).
- **`features/<num>-<slug>/`** — one folder per feature:
  - `feature.md` — the durable record (orientation block, what it does,
    decisions + WHY, gotchas, follow-ups).
  - `handoff.md` — the live baton: status + the exact next move to resume cold.
  - `scratch/` — in-flight working notes; distilled into `feature.md` on ship.

Orientation block (top of every `feature.md`):

```
> **Status**: <active | shipped | abandoned> — <one phrase>
> **Next**: <the single next move>            (drop once shipped)
> **Key files**: <2-4 paths a future agent opens first>
```

*All content under `demo-app/` is synthetic. todo-api is a fictional example.*
