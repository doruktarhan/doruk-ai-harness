# 01-tag-filtering — filter todos by tag

> **Status**: active — endpoint + query-param matching work; one test + PR remain
> **Next**: add `test_filter_is_case_insensitive`, then open the PR
> **Key files**: `src/app.py` (`list_todos`) · `src/test_app.py` · `scratch/notes.md`

## What it does
Adds an optional `?tag=` query parameter to `GET /todos`. With no parameter the
endpoint returns every todo (unchanged). With `?tag=api` it returns only todos
whose `tags` array carries that tag. Matching is case-insensitive and trims
surrounding whitespace, so `?tag=API` and `?tag=%20api%20` both match `"api"`.

## Decisions + WHY
- **Filter in the handler, not a new route.** Keeping it on `GET /todos` behind a
  query param means existing callers (no param) are untouched and we don't fork a
  second list endpoint to maintain. A new `/todos/by-tag/<tag>` would duplicate
  the listing logic for no gain.
- **Case-insensitive + trimmed matching.** Tags are user-supplied strings; callers
  will inevitably send `API`, `Api`, or a stray space. Normalizing both sides
  (`.strip().lower()`) avoids a class of "why didn't my filter match?" bugs. WHY
  it matters: the alternative (exact match) looks correct in the happy-path test
  and silently fails in real use.
- **No multi-tag / AND-OR semantics yet.** Single tag only. Multi-tag filtering
  (`?tag=a&tag=b`) is a real ask but doubles the surface (AND vs OR); deferred to
  a follow-up rather than guessed at now. See `scratch/notes.md`.

## Gotchas
- The store is an **in-memory list** (`_TODOS` in `src/app.py`). Filtering is a
  Python list comprehension, not a DB query — fine at demo scale, but anyone
  swapping in a database must move the filter into the query, not keep it in
  Python, or it won't scale. (Tracked in STATE backlog → Persistence.)
- Tags are compared lowercased on **both** sides every call. If a real DB lands,
  store a normalized tag column rather than lowercasing on read.

## Follow-ups
- Multi-tag filtering with explicit AND/OR semantics (deferred above).
- Feature 02 (rate-limiting) touches the same `/todos` route — land this first to
  avoid a merge collision. Flagged in STATE.

## Files in this folder
| path | role | keep? |
|------|------|-------|
| `handoff.md` | live baton — status + exact next move | keep (until shipped) |
| `scratch/notes.md` | in-flight working notes; distill on ship | scratch |
