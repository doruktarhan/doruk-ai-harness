---
title: Stack and conventions
scope: project-wide
status: durable
created: 2026-06-20
updated: 2026-06-26
tags: [stack, conventions, onboarding]
---

# Stack and conventions

What todo-api is built on and the house rules. Load this first on any new session.

## Stack
- **Python + Flask**, single-file app at `src/app.py`. No blueprints, no factory
  pattern — it's small on purpose. Don't add framework structure until the app
  earns it.
- **pytest** for tests, in `src/test_app.py`. Use Flask's `app.test_client()`;
  no live server needed in tests.
- **Store**: an in-memory Python list. See `in-memory-store-constraint.md` — this
  is a deliberate constraint, not a temporary hack to rip out.

## Conventions
- **Routes** use Flask's method decorators (`@app.get`, `@app.post`), not
  `@app.route(..., methods=[...])`. Keep it consistent.
- **JSON in / JSON out.** Every endpoint returns `jsonify(...)`. POST reads
  `request.get_json()`.
- **Feature folders**: one per feature under `.doruk/features/<num>-<slug>/`,
  with `feature.md` + `handoff.md`. Numbering is sequential.

## Run commands
```
flask --app src/app run        # serve on :5000
pytest src/                    # run tests
curl localhost:5000/health     # liveness check -> {"status":"ok"}
```
