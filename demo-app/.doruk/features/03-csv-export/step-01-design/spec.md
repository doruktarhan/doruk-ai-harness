# CSV export spec — approved 2026-06-29

## Columns (in order)
| # | header | source field | notes |
|---|--------|-------------|-------|
| 1 | `id` | `todo.id` | integer |
| 2 | `title` | `todo.title` | string |
| 3 | `done` | `todo.done` | `true` / `false` |
| 4 | `tags` | `todo.tags` | pipe-separated, e.g. `work\|urgent`; empty string if none |
| 5 | `created_at` | `todo.created_at` | ISO 8601, e.g. `2026-06-29T14:00:00Z`; empty if absent |
| 6 | `updated_at` | `todo.updated_at` | ISO 8601; empty if absent |

## URL
`GET /todos/export.csv`

## Headers
```
Content-Type: text/csv; charset=utf-8
Content-Disposition: attachment; filename="todos.csv"
```

## Empty-field policy
Optional fields (`created_at`, `updated_at`, `tags`) render as an empty cell, not `"null"` or `"N/A"`.

## Decisions
- stdlib `csv.writer` — no new dependencies.
- Tags joined with `|` so the cell stays a single quoted CSV field.
- Always includes the header row, even when the store is empty.
