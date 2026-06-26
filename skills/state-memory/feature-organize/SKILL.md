---
name: feature-organize
description: Distill a .doruk/ feature folder once work ships — rewrite feature.md into a durable record a future agent can read, and triage the in-flight scratch (keep / archive / delete). Full mode (default) rewrites feature.md and triages every aux file once the whole feature closes; narrow mode appends one tight note and deletes a single shipped sub-deliverable's scratch mid-feature. Use when a feature closes, when a sub-deliverable ships inside a still-active feature, or when a handoff skill reports finished/abandoned. Git history is the deletion backstop.
argument-hint: "<feature-folder-name> [shipped|research-only|abandoned|narrow [<sub-path>]]"
user_invocable: true
---

# feature-organize — post-ship distillation

Distills a `.doruk/features/<folder>/` dump so a future agent reading it finds the
**durable knowledge**, not the in-flight scratch.

While work is in flight, agents dump freely into the folder: specs, plans, iteration
notes, review back-and-forth. This skill turns that dump into a clean record — either
**incrementally**, as each sub-deliverable ships (narrow mode), or in **one pass** when
the whole feature closes (full mode).

This is the on-ship companion to a state/handoff skill. Handoff keeps the *live* state of
in-flight work; feature-organize is the step that runs when work **closes**, distilling
that live state into something that survives. A handoff skill can auto-invoke this on its
`finished` / `abandoning` paths, or you can run it manually.

## Two modes

Pick by **scope**, then flavor:

| | **Full** *(default)* | **Narrow** — sub-deliverable distill |
|---|---|---|
| Unit | the whole feature folder | one just-shipped sub-deliverable inside it |
| When | the feature is closing (all tracks done) | mid-feature — one track shipped, others still in flight |
| `feature.md` | rewrites it | **appends** a tight note; leaves sibling sections alone |
| Aux files | triages every one (keep / archive / **never delete**) | touches only that deliverable's files — and **may delete** them (gated) |
| Who runs it | any agent — re-reads everything | the agent that did the work, **in-session** — it already knows what shipped, the divergences, and which files are its scratch |

When the finished thing is a sub-deliverable of a still-active feature, route to **narrow**;
when the whole feature closes, route to **full**. When it's genuinely unclear which, ask
the user.

## Inputs

- **Folder name** + **sub-path**: in-session, **infer both from the chat** — the feature
  folder and the scratch files you just worked on. The user should be able to type a bare
  `/feature-organize narrow` and you resolve the rest. Explicit args are only a fallback
  for a fresh agent with no context.
- **Mode / flavor** (optional, defaults to full mode + `shipped`): `shipped` |
  `research-only` | `abandoned` set full-mode emphasis; `narrow` selects narrow mode for
  the sub-deliverable you just shipped.

## Full mode — algorithm

1. **Gather**
   - Read every file in `.doruk/features/<folder>/`.
   - If `feature.md` links a PR (or your repo wrapper provides PR context), fetch its
     title + body for the record. This skill assumes only git history; a PR-based repo can
     wrap it to fetch PR context first.
2. **Distill `feature.md`** — agent's judgment on shape. Always include:
   - Title + the orientation block (see below)
   - **What it does** — 2-3 sentences
   - **What changed** — PRs/commits, files touched (table if helpful)
   - **Decisions + WHY** — macro choices only; the WHY is what survives
   - **Gotchas** — non-obvious things future agents need
   - **Follow-ups / carryovers** — pointers to next features or open issues
   - **Files in this folder** — navigator table, only if auxiliary files survive
3. **Triage auxiliary files** — for each non-`feature.md` file, apply the filter below:
   keep at top level, move to `archive/`, or leave alone. **Full mode never auto-deletes.**
   When uncertain, archive.
4. **Empty the live handoff** — if the folder has a per-feature `handoff.md` (or equivalent
   live-state file), set its status to done; its live state now lives in `feature.md`.
5. **Show the diff** of all planned changes (rewrites, moves, deletions) and **ask the user
   to confirm.** Then apply.

## Narrow mode — sub-deliverable distill

For one sub-deliverable that just shipped inside a still-active multi-track folder. Run it
**from the session that did the work** — you already know what shipped and what diverged,
so you distill from memory, not by re-deriving from files.

**Precondition:** the sub-deliverable is **merged** (or otherwise landed in git history).
That merged work is the backstop for everything you delete — no backstop, no delete (fall
back to archive).

1. **Infer the scope from the chat** — the parent feature folder + this deliverable's
   scratch (e.g. `SPEC.md` / `PLAN.md` / a sub-folder) are whatever you just created or
   edited this session. Don't make the user hunt for the path; state the resolved folder +
   files in the confirm step so they can correct you. Only a fresh agent with zero context
   falls back to a `<sub-path>` arg or asks. **Never pull sibling-track files into scope.**
2. **Append a tight note** to the existing `feature.md`, under the relevant
   decision/section: decision + WHY + **divergences from the plan** + a pointer to the
   merged work, ~3-5 lines. Close it with a marker like
   `(SPEC/PLAN distilled into this note + deleted; full detail = the merged diff.)`. Do
   **not** rewrite other sections.
3. **Fix only stale lines** about this deliverable — typically the orientation/status line
   ("next" → "shipped").
4. **Delete** the deliverable's scratch + the now-empty sub-folder — only files that pass
   the delete gate (filter below). Anything that doesn't → archive.
5. **Leave everything else untouched** — sibling tracks, rosters, other agents' files.
6. **Show the diff** (the `feature.md` edit + the deletions) and confirm before applying.

**Abandoned sub-deliverable** (work died, won't land): same narrow shape, but the note
captures *why abandoned* + any salvageable learning, and you **do not delete** the scratch —
there's no merged backstop, so archive it or leave it. Mark the section's old "resume
checklist" obsolete rather than erasing the record.

## The keep / archive / delete filter

The single rule that does the real work:

> **Keep** (top level): anything that would change a future agent's decisions —
> architecture, load-bearing constraints, failure modes hit, "looks wrong but is right
> because…", runbooks, gotchas.
>
> **Archive** (`archive/`): true only *during* the work — intermediate naming debates,
> mid-implementation iterations, rebase mechanics, "X suggested A but we did B".
>
> **Delete** *(narrow mode only)*: scratch of a **shipped** sub-deliverable whose every
> decision now lives in the `feature.md` note **and** whose full detail survives in
> **git history** (a merged change). A shipped sub-deliverable's SPEC/PLAN qualifies;
> design rationale that never reached a merged change does **not** — archive that.

Test: if a future agent reading `feature.md` would say *"glad they wrote that down"* →
keep. If they'd skim past → archive. **Full mode never deletes** — the delete tier exists
only in narrow mode, where git history is the backstop.

## Orientation block (first thing after the title)

A short header a future agent reads first. Status is terminal here:

```
> **Status**: shipped — merged YYYY-MM-DD   (or: research only — <what> · abandoned — <why + replacement>)
> **Key files**: <2–4 paths a future agent opens first>
```

Drop transient fields like `Next` / `Active sub-folder` once the work has shipped.

## Flavor-specific emphasis (full mode)

| Flavor | `feature.md` emphasizes |
|---|---|
| `shipped` | what changed + decisions + gotchas + follow-ups |
| `research-only` | findings + recommendations + open questions + where the knowledge applies |
| `abandoned` | why abandoned + what was learned + pointer to replacement (if any) |

## Output shapes (not mandatory)

- A **single-file feature**: just a distilled `feature.md` — orientation block, what it
  does, decisions + WHY, gotchas, follow-ups. No aux files survive.
- A **multi-file feature**: `feature.md` plus a few kept aux files (e.g. a design-rationale
  doc, a smoke runbook) and an `archive/` of during-the-work scratch. Every surviving
  auxiliary file is referenced from `feature.md`'s navigator table.
- A **narrow distill**: `feature.md` gains one tight bullet (decision + WHY +
  divergence-from-plan + pointer to the merged change), and that sub-deliverable's SPEC/PLAN
  are deleted — git history holds the full detail.

## Confirmation

The diff is shown before any file is rewritten, moved, or deleted. No surprise overwrites —
the user can edit or reject any part.
