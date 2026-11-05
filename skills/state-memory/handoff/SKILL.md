---
name: handoff
description: Use when ending a session, changing a feature's status, splitting a feature into tasks, or finishing, abandoning, or picking up a feature — handoff and state-tracking for any repo through a .doruk/ folder (STATE.md landscape + each feature's live handoff.md); bootstraps .doruk/ on first use. Reach for it from a project wrapper skill that adds commit or PR rituals.
argument-hint: "[continuing <note> | finished <feature> | abandoning <feature> | picking-up <feature>]"
user_invocable: true
---

# Handoff — universal .doruk state

This skill organizes `.doruk/` — a portable state folder that any agent reads to orient
itself across sessions, devices, and parallel runs. Nothing here is project-specific: drop
the folder into any repo and it works the same way.

The point: an LLM coding session is stateless. Without a durable, agent-readable record of
*where the work stands* and *what the next move is*, every new session (or device, or
parallel agent) re-derives context from scratch and drifts. `.doruk/` is that record — small
enough to read first, structured enough to trust.

## Layout

```
.doruk/
  STATE.md                  # landscape: one row per feature + its open tasks
  BACKLOG.md                # planned future work with no folder yet, by level
  features/NN-slug/         # numbered, slugged, PERMANENT (update, never delete)
    feature.md              # durable: orientation block + decisions + WHY
    handoff.md              # live: Tasks board + Doing / Next / don't-touch (Markov)
    task-NN-slug/SPEC.md    # optional: a delegated task's spec (multi-task features only)
```

Three tiers, no overlap:

- **STATE.md** — thin index of features and their open tasks. Read first.
- **BACKLOG.md** — future work we plan but haven't scoped. Read when choosing what to start.
- **handoff.md** — one feature's live coordination: task board + current work.
- **feature.md** — durable record (the orientation block plus decisions and WHY). Written
  on ship by a distillation step, not by routine handoffs.

## Rules

- **STATE.md is a dashboard, not a news feed.** It contains exactly four blocks: the
  `> Updated:` header (plus any standing constraints, e.g. a deadline), the active table,
  a `## Done` one-liner list, and a one-line pointer to `BACKLOG.md`. The row IS the news — session detail goes
  in the feature's `handoff.md`, never in blockquotes above the table.
- **A STATE row is:** status · what the feature is in a few words · its open tasks or next
  move in ≤2 sentences · pointer to the folder. An open task of an existing feature lives
  here and in its `handoff.md`, never in `BACKLOG.md`. History,
  decisions, and shipped detail live in `handoff.md` / `feature.md`.
- **Markov** — write current state only; never append history. Git history is your audit log.
- **Update both** the feature's `handoff.md` and its `STATE.md` row, every time; they must agree.
- **Reference, don't duplicate** — point at `feature.md`; carry live state only.
- **Re-read** `STATE.md` and the feature `handoff.md` immediately before editing — another
  agent or device may have changed them.
- **New feature, no folder** → create `features/<next-NN>-<slug>/` (feature.md + handoff.md)
  and add a STATE row.
- **Tasks live in `handoff.md`** — split a feature into a `## Tasks` board there; an agent
  told "Task NN is yours" reads handoff.md (and `task-NN-slug/SPEC.md` if present) and
  executes. Durable plan and decisions graduate to feature.md on ship.
- **Backlog** — work we plan but haven't scoped or started lives in `BACKLOG.md`, under four
  levels: `## Quick wins` (under a day, no design), `## Next builds` (needs a scope, soon),
  `## Later` (mid/long term), `## Waiting on a trigger` (starts when something happens; name
  it). Each item: one or two lines of what and why, plus its source feature if any. A folder
  is created only when the user scopes or starts the item, or asks for one; that
  **deletes its backlog line** (one home per piece of work). A repo whose STATE.md still has
  `## Backlog` moves it into `BACKLOG.md` on the next handoff.
- **Worktree (optional)** — add `> Branch:` / `> Worktree:` to handoff.md; note owner/branch
  in the STATE row.
  In a non-main worktree, handoff.md is edited and committed on that branch, but `STATE.md`
  is edited and committed **in the main checkout** (path from `git worktree list` or
  `.claude/WORKTREE.md`) — never in the worktree, so branch merges stay conflict-free.
- Bump `> Updated:` to today. If `.doruk/` is committed, commit and push after.

## Bootstrap (no `.doruk/` yet)

Create `STATE.md` (empty table + `## Done` + backlog pointer), `BACKLOG.md` (the four empty
level headings) and a `features/` directory.

- **Commit `.doruk/` in personal/solo repos** so state travels across devices.
- **Gitignore it in shared/team repos** as a private workspace.

Ask once if which case applies isn't obvious.

## Behavior by argument

| Argument | Action |
|---|---|
| (none) / `continuing <note>` | Rewrite the active feature's `handoff.md` to current truth (trim, don't append); update its STATE row. Then sweep the table: any *active* row whose next move you can't name as a concrete action, flag to the user for close-out. |
| `picking-up <feature>` | Read its `feature.md` + `handoff.md` to load context; set yourself as owner in STATE. |
| `finished <feature>` | Distill the feature's durable record into `feature.md` first (a `/feature-organize`-style step if you have one); then set `handoff.md` Status to done and demote the STATE row to a one-liner under `## Done` — same session, no judgment call. |
| `abandoning <feature>` | Distill / mark the feature abandoned in `feature.md` first; then set the STATE row to abandoned with a one-line why. |

## Templates

`STATE.md`:

```
# STATE — <repo>
> Updated: YYYY-MM-DD

| # | feature | status | open tasks / next move | owner/branch | folder |
|---|---------|--------|------------------------|--------------|--------|
| 01 | <slug>: <what, few words> | active | <≤2 sentences> | <agent> | `features/01-<slug>/` |

## Done (durable record in each folder's feature.md)
- NN <slug> — <one-line outcome>

Backlog: `BACKLOG.md`
```

`BACKLOG.md`:

```
# BACKLOG — <repo>
> Updated: YYYY-MM-DD

## Quick wins
- <item> — <what and why, 1-2 lines> (from NN-slug, if any)
## Next builds
## Later
## Waiting on a trigger
- <item> — starts when <trigger>
```

Status ∈ active · pickup-ready · parked · done. The table holds only non-done rows;
finished/abandoned features live as one-liners under `## Done`. These four blocks are the
whole file — no other sections. `ls features/` is the full index.

`features/NN-slug/handoff.md`:

```
# <NN-slug> — handoff
> Updated: YYYY-MM-DD · Status: active|pickup-ready|parked|done
> Branch: <b>   (optional)

## Tasks            (multi-task features only; omit if single-task)
| # | task | status | owner | spec |
|---|------|--------|-------|------|
| 01 | <task> | open|in-progress|done | <agent / —> | task-01-<slug>/ (if any) |

## Doing
<current state, 1-3 lines — or per-agent fenced blocks if concurrent>
## Next
<single next move — STATE's one-liner derives from this>
## Micro-decisions
- <volatile; promote durable ones to feature.md on ship>
## Don't touch
<hint, or "—">
```

`feature.md` orientation block (top of the durable file; the full distillation is a
separate ship-time step):

```
# <NN-slug> — <title>
> Status: <state> — <phrase>
> Key files: <2-4 paths>
```

## Concurrency (only when it happens)

For multiple agents on one feature, fence each agent's block in `handoff.md` with
`<!-- AGENT:<slug> START -->` / `<!-- AGENT:<slug> END -->` and edit only your own block.
Don't add this machinery until concurrency actually occurs.

The test for keeping an entry live vs retiring it: **"what's the next move?"** If you can
name a concrete next action, it stays active. If you can't, and the work has shipped or
been abandoned, demote it to a one-line note (or remove it) — the durable record already
lives in `feature.md`.
