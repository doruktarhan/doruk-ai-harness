# feature-organize

**The on-ship distillation step for a `.doruk/` feature folder.** When work closes, it
rewrites that folder's `feature.md` into a durable record a future agent can actually read,
and triages the in-flight scratch into keep / archive / delete.

## What it does

While a feature is in flight, agents dump freely into `.doruk/features/<folder>/`: specs,
plans, iteration notes, review back-and-forth. That's good — friction-free capture is the
point. But left alone, the next agent who opens the folder drowns in stale scratch and
can't tell the load-bearing decision from the abandoned tangent.

feature-organize is the cleanup pass that runs when the work **ships**:

- **Full mode** (default) — the whole feature closed. It rewrites `feature.md` (orientation
  block, what it does, decisions + WHY, gotchas, follow-ups), triages every aux file, and
  empties the live handoff. Never deletes.
- **Narrow mode** — one sub-deliverable shipped inside a still-active feature. It appends
  one tight note (decision + WHY + how it diverged from the plan) and deletes just that
  deliverable's scratch, because git history holds the full detail.

The core is one filter: **keep** what would change a future agent's decisions, **archive**
what was only true during the work, **delete** (narrow mode only) shipped scratch whose
detail survives in git. Nothing is rewritten, moved, or deleted until you confirm a diff.

## Why I built it

I kept losing the *why*. Months later I'd reopen a feature folder and find ten scratch
files, a half-finished plan, and three contradictory notes — but not the one sentence that
explained why I built it that way. The decision was real and load-bearing, and it had
evaporated into noise.

The fix isn't "be tidier while you work" — that kills the speed that makes scratch useful.
The fix is a distillation step at the moment of shipping, when I still remember what
mattered and what was a dead end. That's the cheapest possible time to write it down, and
the most valuable. feature-organize makes that step a single command instead of a chore I
skip.

It pairs with my handoff skill: handoff tracks the *live* state of in-flight work;
feature-organize is what fires when that work closes and turns the live state into a record
that lasts.

## How to use it

Drop the folder into your skills directory:

```
cp -r feature-organize ~/.claude/skills/
```

It expects a `.doruk/` state folder with per-feature subfolders (`.doruk/features/<name>/`
each containing a `feature.md`). My handoff skill bootstraps that layout; you can also
create it by hand.

Then, when a feature ships:

```
/feature-organize <folder-name>            # full distill of a closed feature
/feature-organize <folder-name> abandoned  # flavor: why it died + what was learned
/feature-organize narrow                    # one shipped sub-deliverable, inferred from the chat
```

Run it manually, or wire your handoff/PR wrapper to auto-invoke it on the
finished / abandoned paths. It assumes only git history as the deletion backstop; a
repo that uses PRs can wrap it to pull PR context into the record first.

It always shows you the diff and waits for confirmation before touching a file.
