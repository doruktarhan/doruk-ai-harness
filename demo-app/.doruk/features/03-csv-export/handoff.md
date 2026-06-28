# 03-csv-export — handoff
> Updated: 2026-06-29 · Status: active
> Roadmap position: **at Step 02 (in progress).** Spine + done-criteria → `roadmap.md`.

## Doing
Step 01 (Design) complete — `step-01-design/spec.md` approved: 6-column CSV, `GET /todos/export.csv`,
empty optional fields rendered as empty cells. Now implementing the endpoint in `src/app.py`.
Flask route scaffolded; `csv.writer` plumbed in; `Content-Disposition` header not yet set.

## Next
Finish the `Content-Disposition: attachment; filename="todos.csv"` header, then run the existing
`pytest` suite to confirm no regressions before moving to Step 03 (Test).

## Micro-decisions
- stdlib `csv.writer` over any third-party lib — no new deps in the demo.
- URL: `GET /todos/export.csv` (not `?format=csv`) — cleaner for browser "Save As" behavior.
- Empty optional fields: empty cell, not the string `"null"` — matches the spec.

## Don't touch
`step-01-design/spec.md` — approved, frozen. If the column set changes, re-run Step 01 rather
than editing the approved spec in place.
