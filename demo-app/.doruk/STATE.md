# STATE — todo-api (demo)
> Updated: 2026-06-26
> Synthetic example project. One source of truth for where every feature stands.

| # | feature | status | next move | owner/branch | folder |
|---|---------|--------|-----------|--------------|--------|
| 01 | tag-filtering | active | endpoint + 2 tests done; case-insensitive match works in code but is **untested**. Next: add `test_filter_is_case_insensitive`, then open PR | agent / `feat/01-tag-filtering` | `features/01-tag-filtering/` |
| 02 | rate-limiting | planned | not started — gated on 01 merging (shares the `/todos` route). Next: write spec for a per-IP token-bucket limiter | unassigned | (no folder yet) |

## Backlog

Future work only — not a re-log of what's already in the table above.

- **Persistence** — the store is in-memory (`_TODOS` list in `src/app.py`).
  Swap for SQLite once the API surface stabilizes. Blocked by nothing; low
  priority until there's more than one writer.
- **Pagination** — `GET /todos` returns everything. Add `?limit=&offset=` when
  the list grows. Parked.
- **Auth** — no auth on any route. Out of scope for the demo; noted so a reader
  knows it's a deliberate omission, not an oversight.

## Recent / Paused threads

- features/01-tag-filtering — endpoint + tests landed this session; one
  case-insensitivity test + PR remain. Warm.

*Demo data. Nothing here ships.*
