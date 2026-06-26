# scratch — tag-filtering working notes

In-flight thinking. Gets distilled into `feature.md` (or deleted) when the
feature ships. Kept rough on purpose — this is what the dump actually looks like.

## Open question: multi-tag
`?tag=a&tag=b` — should it be AND (todo has both) or OR (todo has either)?
- AND reads like "narrow it down" (most filter UIs).
- OR reads like "show me anything in these buckets".
Flask gives `request.args.getlist("tag")` for the repeated-param case.
Decision: punt. Single tag ships now; revisit with a real use case. Don't want
to bake in the wrong default and have callers depend on it.

## Matching
Started with exact match `tag in t["tags"]`. The happy-path test passed, then
poked it by hand with `?tag=API` → empty result. Classic. Switched both sides to
`.strip().lower()`. This is exactly the bug the missing test should pin down.

## Quick manual check (ran this, worked)
    flask --app src/app run
    curl 'localhost:5000/todos?tag=api'   -> 2 todos
    curl 'localhost:5000/todos?tag=API'   -> same 2 todos
    curl 'localhost:5000/todos?tag=nope'  -> []

## Leftover
- Decide whether empty `?tag=` (present but blank) means "all" or "none".
  Currently: blank string matches nothing because no tag equals "". Acceptable
  for now; note it if a test complains.
