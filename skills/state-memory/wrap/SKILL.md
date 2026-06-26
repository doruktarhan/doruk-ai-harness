---
name: wrap
description: Wrap up an agent session in a multi-agent feature folder under .doruk/features/<feature>/<agent>/. Runs 5 consistency checks (README↔STATE artifact agreement, stale-link scan, cross-folder write detection, HANDOFF.md trim, decisions.md date convention) and then performs the mechanical end-of-session updates (folder README "Last updated", STATE.md section, decisions/future-work appends). Use at the end of a focused session in an agent-owned folder, or when the user says /wrap, "wrap up", "wrap the folder", "finish session". Typically composed with /handoff (run /wrap first, then /handoff).
user_invocable: true
---

# /wrap — Agent Folder Session Wrap-Up

This skill assumes a `.doruk/` state system where multiple agents share one feature but
each owns a single folder. The layout it expects:

```
.doruk/
├── HANDOFF.md                          # one short line per feature (cross-feature index)
└── features/
    └── <feature>/
        ├── STATE.md                    # one section per agent: ## <agent> (last touched YYYY-MM-DD)
        ├── conventions.md              # the multi-agent rules for this feature (optional)
        └── <agent>/                    # single-writer territory — one agent owns this folder
            ├── README.md               # has a "Current state" paragraph + "> Last updated:" line
            ├── decisions.md            # append-only: YYYY-MM-DD · <decision>
            ├── future-work.md          # append-only: deferred items
            └── ...                     # the agent's actual working docs
```

`.doruk/features/<feature>/<agent>/` is **single-writer territory**: one agent writes there,
others read it. When an agent finishes a session in such a folder, `/wrap` enforces the
at-session-end checklist and catches the inconsistencies that multi-agent setups generate
(state drifting between the folder README and the shared STATE.md, links pointing at
archived files, one agent silently editing another's folder).

If your `.doruk/` doesn't use the per-agent-folder split — if each feature has a single
owner — you don't need `/wrap`; `/handoff` alone covers you.

## When to use

- You've finished a focused work session in an agent-owned folder
- About to run `/handoff` (which updates the shared handoff file)
- User says: "wrap up", "wrap the folder", "/wrap", "finish session", "close out"

## When NOT to use

- You haven't actually edited anything (pure read session)
- You worked across many features (this is per-feature-folder)
- You're not in a `.doruk/features/<X>/<agent>/` shape (e.g. random code edits) — use `/handoff` directly

## Inputs (no args)

The skill is invoked as `/wrap` with no arguments. It infers everything from session context.

You determine:

1. **Which agent folder** — look at the files edited this session. They should sit under
   `.doruk/features/<feature>/<agent>/`. The `<agent>` segment is the folder you're wrapping.
2. **What got done** — recap from conversation context: docs written, decisions locked,
   deferred items, artifacts shipped (build/image IDs, PR numbers, deploy revisions, etc.).
3. **Cross-folder writes** — any file edited OUTSIDE `<agent>/` (other than `STATE.md` or
   `HANDOFF.md`) is a flag.

If you can't determine the agent folder unambiguously (e.g. edits spread across multiple
agent folders), ASK before proceeding.

## Process

### Step 1 — Recap (announce to user before any writes)

State what you understood:
- Agent folder: `<path>`
- What you did this session (1-2 sentences)
- Artifacts produced (build ID, PR #, doc names, deploy revision) — these are what STATE.md will reference

### Step 2 — Run 5 consistency checks

Each check either passes silently or surfaces a concrete fix to make BEFORE writing.

**Check 1: README ↔ STATE artifact agreement**

Open the folder's `README.md` § "Current state" and the proposed new `STATE.md § <agent>`
entry. They both describe the same world, so they must agree on concrete artifacts (build/image
ID, PR #, template path, revision name).

Fail mode caught: STATE.md says v6 is live but the folder README still says v4.

**Check 2: Stale-link scan**

`grep -E '\[.+\]\(([^)]+)\)' <folder>/README.md <feature-root>/STATE.md` and verify each
referenced path:
- File exists (no broken links)
- Path doesn't point at `../archive/` (archived files should not be linked from
  "Where to start" / "Where to look" — they're historical only)

Fail mode caught: STATE.md "Where to start" still links a doc that another agent has since archived.

**Check 3: Cross-folder write detection**

List every file edited this session. For each, check whether it's under `<agent>/` or in the
explicit allowlist (`STATE.md`, `HANDOFF.md`, and any shared append-only log your feature
defines, e.g. `chronology.md`).

Anything else → cross-folder write. Don't auto-fix. Show the user the list and ask:
- "Update the affected folder's owner-docs to match?" (writes a NOTE to that folder's
  STATE.md section as a follow-up flag — don't edit their `decisions.md` or README directly)
- OR "Add a follow-up note to that agent under STATE.md?"

Fail mode caught: one agent writes into a sibling folder without updating that folder's
owner-maintained "blessed" table, so the two now disagree.

**Check 4: HANDOFF.md trim**

Read the current feature's line in `.doruk/HANDOFF.md`. If it's over ~50 words OR contains
stale crumbs (PRs that have since merged, completed phases), propose a condensed replacement.
Show a before/after diff before writing.

Rule: HANDOFF.md is "currently `<X>`; recent `<Y>`". Detail lives in `STATE.md`, not here.

Fail mode caught: a feature line ballooning toward hundreds of words as each agent appends
without trimming.

**Check 5: decisions.md date convention**

If new entries were added to `<folder>/decisions.md`, verify dates are `YYYY-MM-DD · <decision>`
format AND the date is **when decided** (not when documented).

Heuristic: if the underlying PR / commit / discussion happened on date X, the entry should be
dated X. Today's date is correct only for decisions actually locked today.

Fail mode caught: an agent mines an old decision out of an archived doc and dates it today
instead of the original date it was made.

### Step 3 — Mechanical updates (after checks pass)

Show a unified diff of every proposed change. Wait for user OK. Then write:

1. **`<folder>/README.md`**: bump the `> Last updated: YYYY-MM-DD` line. Update the
   one-paragraph "Current state" if reality moved (per Check 1).
2. **`<folder>/decisions.md`**: append any new decisions (with correctly-dated entries per Check 5).
3. **`<folder>/future-work.md`**: append any newly deferred items.
4. **`<feature-root>/STATE.md`**: under `## <agent> (last touched YYYY-MM-DD)`, write a 2-4
   line entry. Format: 1 sentence on what changed this session + 1 sentence on the next pickup
   point. Don't touch other agents' sections.
5. **Append-only event logs** if your feature uses them (e.g. a `promotions/YYYY-MM-DD-<event>.md`
   per release).

### Step 4 — Tell the user what's left

End with a 3-line summary:
- ✅ What was written
- ⏭ Whether `/handoff` should run next (yes, if this session produced feature-level visible change)
- ⚠ Any check that failed and was deferred (e.g. user said "skip the cross-folder write for now")

## Examples

### Example 1 — clean session

```
User: /wrap

Agent: Recap: I just finished structuring the db/ folder for the data-model feature —
wrote schema.md, migrations.md, backfill.md, prod-promotion.md; mined 10 decisions
from the now-archived considerations.md.

Running checks…
✅ Check 1: README current-state matches STATE.md (both describe migration 000051 live on staging)
✅ Check 2: No stale links
✅ Check 3: All edits are under db/ (or STATE.md). Single-writer OK.
✅ Check 4: HANDOFF.md feature line is 280 words — propose trim to 45.
✅ Check 5: decisions.md entries dated to when decided (in the PR), not today. OK.

Proposed writes: <diff>
OK?

User: yes

Agent: Done. Suggest /handoff next (the new docs are feature-level visible).
```

### Example 2 — cross-folder violation

```
User: /wrap

Agent: Recap: I just promoted the v6 dashboard design from prototype to the staging
deploy (build 3bed0616, revision ...-00003).

Running checks…
✅ Check 1: app/README.md current-state mentions v6 ✓
✅ Check 2: No stale links
❌ Check 3: I wrote `design/promotions/2026-05-13-promote-v6.md`.
   This is in `design/`, not my `app/` folder. The design agent owns
   `design/decisions.md` (still says v4 blessed) and `design/workflow.md`
   (blessed-design table still says v4).

Two options:
  (a) Add a follow-up note to STATE.md § design saying "v6 promoted by app
      agent on 2026-05-13 — design folder needs blessed-table update next session"
  (b) Update design/decisions.md + design/README.md + design/workflow.md to
      reflect v6 (violates single-writer but keeps state consistent)

Recommendation: (a). Single-writer matters more than instant consistency; the
design agent reads STATE.md before its next session.

User: a

Agent: <appends follow-up note to STATE.md § design>
Proceeding with the rest of the checks…
```

## Don'ts

- Don't write to another agent's folder. Flag cross-folder issues via Check 3 and route them
  through `STATE.md` notes.
- Don't auto-fix decisions.md dates without asking — the date convention is "when decided",
  and the agent may legitimately know a different date than the heuristic guesses.
- Don't run on non-feature-folder edits. If the user is just doing code work, `/handoff`
  alone is enough.
- Don't bump `HANDOFF.md` from inside `/wrap`. It composes with `/handoff` — keep the
  concerns separated.

## Related skills

- `/handoff` — run AFTER `/wrap` for the shared handoff file update
- Convention contract: `.doruk/features/<feature>/conventions.md` holds the multi-agent rules
