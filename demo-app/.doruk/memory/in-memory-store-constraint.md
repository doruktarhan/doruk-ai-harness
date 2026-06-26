---
title: The store is process-local and in-memory
scope: data-layer
status: durable
created: 2026-06-20
updated: 2026-06-22
tags: [constraint, data, gotcha]
---

# The store is process-local and in-memory

`_TODOS` in `src/app.py` is a plain Python list living in the process. This is a
**load-bearing constraint**, written down so nobody trips on it twice.

## What follows from it
- **No persistence.** Restart the server and every todo is gone, including ones
  created via `POST /todos`. Tests rely on the seed data being reset per process.
- **No concurrency safety.** Two workers (e.g. gunicorn with >1 worker) get
  separate lists and disagree about state. Run single-process for the demo.
- **Filtering happens in Python**, not in a query. Fine at three todos. The moment
  a real database lands, the filter logic in `list_todos()` must move into the
  query — leaving it in Python would load the whole table per request.

## Why it's like this (not a bug)
todo-api is a demo of the harness, not a product. The in-memory store keeps the
app to one readable file. **Don't "fix" it** by adding a DB unless a feature
actually needs persistence — that's tracked in `STATE.md` → Backlog → Persistence,
gated on the API surface stabilizing.

## If you do add a DB
- Move filtering into the query layer.
- Store a normalized (lowercased, trimmed) tag value so you don't normalize on
  every read — see `query-param-normalization.md`.
