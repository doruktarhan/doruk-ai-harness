"""Tests for todo-api. Synthetic demo data.

Note the deliberate gap: there is NO test yet for case-insensitive tag
matching. That gap is on purpose — feature 01 is mid-flight, and adding
this test is its exact next move. See
.doruk/features/01-tag-filtering/handoff.md.
"""

from app import app


def client():
    app.config["TESTING"] = True
    return app.test_client()


def test_list_all_todos():
    res = client().get("/todos")
    assert res.status_code == 200
    assert len(res.get_json()) == 3


def test_filter_by_tag():
    res = client().get("/todos?tag=api")
    assert res.status_code == 200
    titles = [t["title"] for t in res.get_json()]
    assert "ship tag filtering" in titles
    assert "write the spec" not in titles


def test_create_todo():
    res = client().post("/todos", json={"title": "demo", "tags": ["x"]})
    assert res.status_code == 201
    assert res.get_json()["done"] is False


# TODO(feature-01): add test_filter_is_case_insensitive — ?tag=API should match "api".
