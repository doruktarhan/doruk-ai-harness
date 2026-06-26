"""todo-api — a fictional demo service.

Synthetic example app used only to illustrate the .doruk/ harness.
Not a real product. Single-file Flask app with an in-memory store.
"""

from flask import Flask, jsonify, request

app = Flask(__name__)

# In-memory store. Fine for a demo; a real app would use a database.
_TODOS = [
    {"id": 1, "title": "write the spec", "done": True, "tags": ["docs"]},
    {"id": 2, "title": "ship tag filtering", "done": False, "tags": ["api", "feature"]},
    {"id": 3, "title": "add rate limiting", "done": False, "tags": ["api", "infra"]},
]
_NEXT_ID = 4


@app.get("/todos")
def list_todos():
    """List todos. Optional ?tag= filters to todos carrying that tag.

    Tag filtering is the feature currently in flight — see
    .doruk/features/01-tag-filtering/.
    """
    tag = request.args.get("tag")
    items = _TODOS
    if tag is not None:
        tag = tag.strip().lower()
        items = [t for t in _TODOS if tag in [x.lower() for x in t["tags"]]]
    return jsonify(items)


@app.post("/todos")
def create_todo():
    global _NEXT_ID
    body = request.get_json(force=True) or {}
    todo = {
        "id": _NEXT_ID,
        "title": body.get("title", ""),
        "done": False,
        "tags": body.get("tags", []),
    }
    _TODOS.append(todo)
    _NEXT_ID += 1
    return jsonify(todo), 201


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    app.run(port=5000)
