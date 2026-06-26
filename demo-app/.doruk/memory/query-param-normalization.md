---
title: Normalize user-supplied query params on both sides
scope: api
status: durable
created: 2026-06-25
updated: 2026-06-26
tags: [api, gotcha, validation]
---

# Normalize user-supplied query params on both sides

A gotcha that already bit once during feature 01 (tag-filtering) and will bite
again on any future filter param. Writing it down so it doesn't get re-learned.

## The rule
When matching a user-supplied query parameter against stored data, normalize
**both sides** the same way before comparing. For tags that means
`.strip().lower()` on the incoming value AND on each stored value.

## Why
Users send `API`, `Api`, `" api "`. An exact-match comparison passes its
happy-path test (`?tag=api` against a lowercase tag) and then silently returns
empty for `?tag=API` in real use. The failure is invisible in the obvious test —
which is exactly why feature 01 has a dedicated `test_filter_is_case_insensitive`
as its closing move.

## Where it applies
- `list_todos()` in `src/app.py` (the `?tag=` filter) — current implementation.
- Any future filter param (status, owner, search). Same treatment.
- If a DB lands: normalize once on write (store a normalized column) instead of
  lowercasing on every read. See `in-memory-store-constraint.md`.

## Edge note
A present-but-blank param (`?tag=`) currently matches nothing, since no stored tag
equals the empty string. Decide "all vs none" explicitly if a feature needs blank
to mean something.
