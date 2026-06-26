# 01-tag-filtering — handoff
> Updated: 2026-06-26 · Status: active · Branch: `feat/01-tag-filtering`

## Where it stands
The `?tag=` filter is **implemented and partly tested**:
- `src/app.py` → `list_todos()` reads `?tag=`, normalizes with `.strip().lower()`,
  and filters the in-memory list.
- `src/test_app.py` covers list-all and a happy-path `?tag=api` filter.

## The exact next move (pick this up cold)
1. Add `test_filter_is_case_insensitive` to `src/test_app.py`: assert
   `GET /todos?tag=API` returns the same todos as `?tag=api`. There's a
   `# TODO(feature-01)` marker at the bottom of that file marking the slot.
2. Run `pytest src/` from `demo-app/` — expect all green.
3. Open the PR from `feat/01-tag-filtering`. Title: "feat: filter todos by tag".

## Watch out
- Feature 02 (rate-limiting) edits the same `/todos` route. Merge this first.
- Don't add multi-tag (`?tag=a&tag=b`) here — it's a deliberate follow-up, not
  part of this feature's scope. See `feature.md` → Decisions.
