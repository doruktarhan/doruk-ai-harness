# feature-roadmap — a durable step-spine for multi-step programs

A companion to `handoff` for features that are too big for a single `handoff.md` — a
multi-step program with ordered phases, artifacts per step, and a plan that spans sessions.

## What it does

`/feature-roadmap` adds one file beside `handoff.md`:

- **`roadmap.md`** — the durable step-spine: a mermaid flow + ordered step blocks, each
  with a name, intent, step-folder pointer, and a **Done when** that an agent can check.
  This file doesn't change as you progress — it's the map, not the pin.
- **`handoff.md`** (updated) — shrinks to a pin: `> Roadmap position: at Step N`. Doing /
  Next carry only the current step's live state, not the whole plan.
- **`step-0N-*/` folders** — one per step that produces artifacts (drafts, data, reports).

Three tiers, no overlap: **roadmap.md** = the map · **handoff.md** = the pin · **feature.md** = the
durable record (written on ship by `/feature-organize`).

## Why I built it

`/handoff` works well for features with a few tasks. But some features are *programs* —
craft → test → refine, a migration sweep, an analysis pipeline, or running N items through
a workflow and iterating. Those have ordered steps the agent should see all at once, and a
plan that doesn't change even as individual steps complete.

The problem: `handoff.md` is Markov (rewritten to current truth each session), so a
step-list written there either gets clobbered as you progress or bloats the handoff trying
to carry both the plan and the current state. Trying to preserve the plan in `handoff.md`
turns it into a wall of text that starts to feel unofficial.

The fix is a split: move the durable plan to `roadmap.md` and reduce `handoff.md` to a
two-line pin. An agent picks up a session, reads "at Step 3 (in progress)" in handoff, walks
to `roadmap.md` to see the full picture, comes back to handoff for the live state. No
archaeology through chat logs; no stale plan overwritten by a prior session.

## How to use it

1. Copy this `feature-roadmap/` folder into `~/.claude/skills/` (or your project's
   `.claude/skills/`).
2. Run `/feature-roadmap` when a discussion has converged on an ordered step list —
   **don't author a roadmap from a vague idea**. Steps and their "Done when" must be
   settled first. Use `/discuss` then `/align` to converge if needed.
3. The skill creates `roadmap.md` and updates `handoff.md` to a pin. Each subsequent
   session runs `/handoff` as normal; the handoff just writes "at Step N" instead of
   re-carrying the full plan.

See `demo-app/.doruk/features/03-csv-export/` for a worked example with placeholder content
showing what `roadmap.md`, `handoff.md`, and the step folders look like together.

It composes naturally with `handoff` (which it builds on) and `feature-organize` (which
distills the roadmap into `feature.md` on ship).
