# My persistent memory layer

This is how I carry knowledge across sessions and across machines instead of trusting
the model's context window to remember anything. The whole thing is plain files in a
`.doruk/` folder, committed to git, with an index at the top and a discipline for keeping
it honest. Nothing magical: a directory, a few Markdown files, and the rule that I
actually update them.

I'm writing this in the first person because it's my system and I want to be honest about
why it exists, not sell it.

## Why context-window-only working fails me

When I lean on the context window as my only memory, three things keep going wrong:

- **It evaporates.** A context window lives and dies with one session. The moment I close
  the conversation, or it compacts, or I hit a token ceiling, everything the agent
  "learned" is gone. The next session starts from zero and re-derives the same
  conclusions, often slightly differently.
- **It doesn't travel.** I work across more than one machine. A window open on one laptop
  knows nothing about what I decided on another. There is no shared brain unless I put one
  on disk and sync it.
- **It rots silently.** Even within a long session, the model paraphrases its own earlier
  notes each time it summarizes, and small drift compounds. Status I typed as prose ("this
  is done", "merged", "blocked") is stale almost immediately and I have no way to tell
  fresh from stale later.

A persistent, indexed memory layer fixes each of those. Files survive the session. Files
committed to git travel to every machine I check out the repo on. And an explicit index
plus an update discipline means I can trust what's written, because there's a known place
it lives and a known moment it gets refreshed.

The core trade I'm making: **the context window is working memory (fast, small,
disposable); `.doruk/` is long-term memory (durable, indexed, the source of truth).** When
they disagree, the file wins, and I re-read the file rather than trusting what the agent
thinks it remembers.

## Shape of the layer

Everything lives under a single `.doruk/` folder at the repo root. It's committed to git
on purpose, so state travels across devices: `git pull` at the start of a session and I
have exactly the memory I left on the other machine.

Two kinds of content live there, and I keep them separate:

- **The landscape / index** — a top-level file (I treat `STATE.md` / a `MEMORY.md` index as
  this role) that is the map of everything else. It is *not* where detail lives; it's the
  table of contents plus a one-line "what is this and where does it stand" for each thread.
- **The memory files themselves** — one folder per thread of work (a feature, a topic, a
  long-running concern), each with its own durable record. Detail lives here, never in the
  index.

The split matters. The index stays short enough to read in one glance and orient fast. The
per-thread files can grow as deep as they need to without making the index unreadable. When
I open a fresh session, I read the index first, decide which thread I care about, and only
then open that thread's file. That's the whole point of indexing: I don't pay the cost of
loading everything to find the one thing I need.

## Frontmatter on memory files

Each memory file carries a small frontmatter block at the top: a name, a short
description, and status fields. This is the same convention my skills use, and it earns its
keep for the same reason.

- The **name + description** let me (or an agent) scan a folder of memory files and know
  what each one is *without opening it* — the description is the searchable summary.
- A **status field** in frontmatter is machine-checkable and unambiguous, unlike status
  buried in prose. "Is this thread active or shipped?" should be one field, not a sentence I
  have to interpret.
- It gives every file a **predictable header**, so an agent picking up cold knows exactly
  where to look for orientation: top of the file, every time.

The discipline that pairs with this: keep an **orientation block** at the top of each
thread's record — a current status line plus the next move. When I pick up a thread, I read
that block to load context fast instead of re-reading the whole history.

## The update discipline

The files are only worth anything if they're current, so the discipline is the actual
product here. The rules I hold myself (and any agent acting for me) to:

- **Re-read immediately before editing.** Another session, or another parallel agent, may
  have touched the file since I last looked. I read the current state right before I write,
  so I never clobber someone else's update with a stale copy.
- **Edit in place, don't append-and-grow.** When I update a thread, I rewrite it to a tight
  size and trim stale detail — I don't keep stacking new notes on top of old ones. A file
  that has grown past its soft cap is the signal that detail belongs in a deeper record, not
  that I should let the top-level note bloat.
- **Reference, don't duplicate.** The index points at the thread; the thread holds the
  detail. I never copy the same fact into two places, because then they drift apart and I
  can't tell which is right.
- **Link to live status, don't snapshot it.** Anything whose truth changes over time (a
  pull request's merge state, a deploy's health) I reference by identifier and read live
  when I need it. I never freeze "merged" or "passing" as prose in memory, because it's
  wrong by the next session and worse than no answer, because it *looks* authoritative.
- **Distinguish active from dormant.** The index separates threads I can name a next move
  for (active) from threads that are shipped or paused with no current next action
  (recent / parked). The test is literally "what's the next move?" — if I can name one, it's
  active; if I can't and it's done or dead, it moves to the parked list. This keeps the
  active view honest and short instead of a graveyard of everything I've ever touched.
- **Prune.** Parked entries get removed once their follow-ups close or after they've gone
  cold for a while. The index is a working view, not an archive — the git history of the
  folder is the real archive, so I can delete freely without losing anything.

There's also a **closing ritual**: when a thread finishes (or I abandon it), I distill its
working notes into a durable record and triage the scratch — keep what's worth keeping,
drop the rest. So the memory layer doesn't just accumulate; it gets curated at the natural
boundaries.

## Why git, specifically

Committing `.doruk/` instead of gitignoring it is a deliberate choice and it buys three
things at once:

- **Cross-device sync for free.** No separate database, no service to run. `git pull` and
  the memory is here; `git push` and it's everywhere. The version control I already use is
  the sync layer.
- **History as a safety net.** Because the rules tell me to trim and prune aggressively, I'd
  be nervous about deleting if it were permanent. It isn't: every prior version is in git
  history. The deletion backstop means I can keep the working view ruthlessly small.
- **Auditability.** I can see when a decision was recorded and how a thread's status
  changed over time, which is exactly the thing a context window can never give me.

## The mental model in one line

Treat the context window as RAM and `.doruk/` as the disk: small fast scratch up top, a
durable indexed store underneath, an explicit moment where I flush scratch to disk, and the
discipline that the disk — not the agent's recollection — is the source of truth.
