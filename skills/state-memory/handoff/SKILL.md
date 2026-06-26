---
name: handoff
description: Handoff and state-tracking for any repo through a .doruk/ folder — a STATE.md landscape plus each feature's live handoff.md. Use when ending a session, changing a feature's status, splitting a feature into tasks, or finishing, abandoning, or picking up a feature; bootstraps .doruk/ on first use. Reach for it from a project wrapper skill that adds commit or PR rituals.
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
  STATE.md                  # landscape (one line per feature) + backlog of future work
  features/NN-slug/         # numbered, slugged, PERMANENT (update, never delete)
    feature.md              # durable: orientation block + decisions + WHY
    handoff.md              # live: Tasks board + Doing / Next / don't-touch (Markov)
    task-NN-slug/SPEC.md    # optional: a delegated task's spec (multi-task features only)
```

Three tiers, no overlap:

- **STATE.md** — thin index + backlog. Read first.
- **handoff.md** — one feature's live coordination: task board + current work.
- **feature.md** — durable record (the orientation block plus decisions and WHY). Written
  on ship by a distillation step, not by routine handoffs.

## Rules

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
- **Backlog** — future work with no folder yet lives in `STATE.md` under `## Backlog`;
  promote it to a feature when picked up.
- **Worktree (optional)** — add `> Branch:` / `> Worktree:` to handoff.md; note owner/branch
  in the STATE row.
- Bump `> Updated:` to today. If `.doruk/` is committed, commit and push after.

## Bootstrap (no `.doruk/` yet)

Create `STATE.md` (empty table + `## Backlog`) and a `features/` directory.

- **Commit `.doruk/` in personal/solo repos** so state travels across devices.
- **Gitignore it in shared/team repos** as a private workspace.

Ask once if which case applies isn't obvious.

## Behavior by argument

| Argument | Action |
|---|---|
| (none) / `continuing <note>` | Rewrite the active feature's `handoff.md` to current truth (trim, don't append); update its STATE row. |
| `picking-up <feature>` | Read its `feature.md` + `handoff.md` to load context; set yourself as owner in STATE. |
| `finished <feature>` | Distill the feature's durable record into `feature.md` first (a `/feature-organize`-style step if you have one); then set `handoff.md` Status to done and the STATE row to done. |
| `abandoning <feature>` | Distill / mark the feature abandoned in `feature.md` first; then set the STATE row to abandoned with a one-line why. |

## Templates

`STATE.md`:

```
# STATE — <repo>
> Updated: YYYY-MM-DD

| # | feature | status | next move | owner/branch | folder |
|---|---------|--------|-----------|--------------|--------|
| 01 | <slug> | active | <one phrase> | <agent> | `features/01-<slug>/` |

## Backlog
- <future feature/task> — <one-line intent>   (no folder yet; /handoff promotes it)
```

Status ∈ active · pickup-ready · parked · done. When the table grows, demote done rows to
a one-line note; `ls features/` is the full index.

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
