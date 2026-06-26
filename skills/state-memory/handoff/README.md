# handoff — state & memory for stateless coding agents

A drop-in skill that gives any repo a small, durable memory the agent reads to orient
itself: a `.doruk/` folder with a `STATE.md` landscape and a live `handoff.md` per feature.

## What it does

`/handoff` maintains `.doruk/` for you:

- **STATE.md** — a one-line-per-feature index plus a backlog of future work. Read this first
  in any session and you know the whole landscape.
- **features/NN-slug/handoff.md** — the live coordination for one feature: what's being done
  right now, the single next move, and a task board when the feature splits into tasks.
- **features/NN-slug/feature.md** — the durable record: why the work exists and the decisions
  behind it, distilled when the feature ships.

It's argument-driven — `continuing`, `picking-up`, `finished`, `abandoning` — and bootstraps
the folder on first run. State is **Markov**: each handoff overwrites the current snapshot
instead of appending history, so the file stays small and trustworthy. Git history is the
audit log.

## Why I built it

A coding-agent session is stateless. Close the window and the agent forgets where the work
stood; open it on another machine, or spin up a second agent in parallel, and it re-derives
everything from scratch and drifts. I kept paying that re-orientation tax at the start of
every session.

So I made the state external and agent-readable. `.doruk/` is the first thing an agent reads
and the last thing it updates. The "what's the next move?" test keeps it honest: every live
entry has to name a concrete next action, or it gets demoted — that's what stops it rotting
into a stale wall of text.

The real proof is that **the exact same system runs across two completely unrelated repos**:
a production application with parallel agents and worktrees, and a solo personal project.
Same folder, same skill, no per-repo special-casing. In the solo repo I commit `.doruk/` so
the state follows me across devices; in the shared repo I gitignore it as a private
workspace. One portable contract, two very different worlds.

## How to use it

1. Copy this `handoff/` folder into `~/.claude/skills/` (or your project's
   `.claude/skills/`).
2. In any repo, run `/handoff` to update the active feature, or:
   - `/handoff picking-up <feature>` to load context for an existing feature,
   - `/handoff finished <feature>` to close one out,
   - `/handoff abandoning <feature>` to drop one with a one-line why.
3. First run with no `.doruk/` yet bootstraps the folder. Commit it in solo repos so state
   travels across devices; gitignore it in team repos.

It pairs well with a thin project-specific wrapper skill that adds your commit or PR ritual
on top — this skill stays purely about the state, so the rituals live where they belong.
