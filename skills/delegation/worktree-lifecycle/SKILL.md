---
name: worktree-lifecycle
description: Auto-context for an agent working inside a spawned git worktree. Read .claude/WORKTREE.md for which worktree you're in, then follow the build / test / cleanup lifecycle so isolated branches don't collide and uncommitted work isn't lost.
user_invocable: false
metadata:
  author: doruktarhan
  version: "1.0.0"
  domain: devops
  triggers: auto-loaded in worktrees
  role: context
  scope: worktree
---

# Worktree Lifecycle

You are running inside a **git worktree** — an isolated checkout of a single branch
that lives in its own directory, separate from the main checkout. Multiple worktrees
of the same repo can exist at once, each on a different branch, so several agents can
build and test in parallel without stepping on each other.

This skill is the **operating manual for an agent inside one of those worktrees**: how
to orient, build, test, and clean up without colliding with sibling worktrees or losing
uncommitted work.

## 1. Orient — read your worktree context first

A spawn step should have written a context file at `.claude/WORKTREE.md`. Read it before
doing anything else. It tells you:

- **Which branch** this worktree is on.
- **The worktree's own path** (where you are now).
- **The main checkout's path** (the canonical tree — config lives there).
- Any task-specific notes the spawner left for you.

If `.claude/WORKTREE.md` is missing, fall back to git itself:

```bash
# Where am I, what branch, and what other worktrees exist?
git rev-parse --show-toplevel    # this worktree's root
git branch --show-current        # this worktree's branch
git worktree list                # all worktrees of this repo (paths + branches)
```

## 2. Setup — what the spawn step already did

A worktree-spawn step typically handles the one-time wiring so you don't have to:

- Created the worktree with `git worktree add <path> -b <branch>`.
- Copied **gitignored local files** the build needs but git won't carry across — most
  commonly `.env` files (and any nested ones like `service/.env`, `web/.env.local`).
- Optionally copied agent/editor config (`.claude/`, rules, local skills) so this
  worktree behaves like the main one.

If a build fails because an env file or local config is missing, copy it from the main
checkout (path is in `.claude/WORKTREE.md`) rather than inventing values.

## 3. Build & test — but isolate from sibling worktrees

Run the project's own build and test commands here exactly as you would in the main
checkout. **Use the commands the repo already documents** (check `README.md`,
`CONTRIBUTING.md`, a `Makefile`/`justfile`/`package.json` scripts, or a project-specific
dev skill). Generic shape:

```bash
<install deps>     # e.g. npm ci · pnpm i · uv sync · go mod download
<build>            # e.g. npm run build · go build ./... · cargo build
<test>             # e.g. npm test · uv run pytest · go test ./... · cargo test
```

The one thing that changes inside a worktree is **shared, host-level resources**.
Several worktrees building at once will fight over them unless each one is isolated.
Before you start any long-running process, check what siblings are already using:

```bash
# What ports are already taken on this host?
lsof -iTCP -sTCP:LISTEN -P -n | grep LISTEN

# What container projects are already up (if the stack uses containers)?
docker compose ls 2>/dev/null
docker ps --format '{{.Names}}\t{{.Ports}}' 2>/dev/null
```

Then give **this** worktree its own slice:

- **Pick a free port** (or a per-worktree port offset) for any dev server, API, or DB
  you start, instead of the project default that the main checkout already owns.
- **Use a unique project name** for any container stack (e.g.
  `docker compose -p <branch-slug> up`) so volumes and networks don't collide.
- Tear down what you started when you're done (see Cleanup).

If the repo ships a dev script that already assigns per-worktree ports/projects, prefer
it over starting things by hand.

## 4. Cleanup — when the work is done

```bash
# 1. Stop anything THIS worktree started (servers, watchers, container stacks).
#    e.g. docker compose -p <branch-slug> down   ·   kill the dev-server PID

# 2. Make sure work is committed/pushed if it should be (see Rules), THEN remove the
#    worktree. Run from the main checkout or anywhere outside the worktree dir.
git worktree remove <this-worktree-path>

# If the worktree has changes you intend to discard:
git worktree remove --force <this-worktree-path>

# Tidy stale administrative entries afterwards.
git worktree prune
```

## Rules

1. **Never push from a worktree without the user's explicit ask.** Worktrees are scratch
   space; pushing is a deliberate, asked-for action.
2. **Don't edit shared agent/editor config inside a worktree** (e.g. global skills or
   rules that were *copied* in). Those are copies — change them in the main checkout so
   the change is real and tracked.
3. **Isolate host resources.** Each worktree gets its own ports and its own container
   project name. Never assume the project defaults are free — a sibling may hold them.
4. **Assess before you start.** Check listening ports / running stacks before launching
   anything long-running, so you don't collide.
5. **Commit early and often.** A worktree can be removed at any time and uncommitted work
   in it is gone. Don't keep meaningful work uncommitted.
6. **Stay in your lane.** Do task work on *this* branch in *this* directory. Don't reach
   into a sibling worktree or check out a different branch here.
