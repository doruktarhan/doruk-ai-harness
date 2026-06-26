# worktree-lifecycle

A skill that auto-loads for an agent working **inside a spawned git worktree** and gives
it the operating manual for that environment: orient → build → test → clean up, without
colliding with sibling worktrees or losing uncommitted work.

## What it does

When I (or one of my agents) am dropped into an isolated worktree, this skill kicks in and:

- **Orients me** — reads `.claude/WORKTREE.md` (or falls back to `git worktree list`) so I
  know which branch I'm on, where I am, and where the main checkout lives.
- **Reminds me what setup already happened** — gitignored `.env` files and local config the
  spawn step copied in, so a missing-env build failure has an obvious fix.
- **Keeps me from colliding** — assess ports and running stacks first, then claim a free
  port and a unique container project name for *this* worktree.
- **Cleans up correctly** — stop what I started, commit/push only when asked, then
  `git worktree remove` and `prune`.

## Why I built it

I run multiple agents in parallel, each in its own git worktree, so several branches get
built and tested at the same time. The failures were always the same dumb ones: two
worktrees fighting over the same dev-server port or container project, a build dying
because a gitignored `.env` never got copied across, or an agent losing real work because
a worktree got removed before anything was committed. The mechanics of "you are in a
worktree, here's how to behave" don't fit in a single instruction line, so I turned them
into a context skill that loads itself the moment an agent is inside one. It encodes the
isolation discipline once instead of me re-explaining it to every agent.

## How to use it

Drop the folder into your skills directory:

```bash
cp -r worktree-lifecycle ~/.claude/skills/
```

It's a **context skill** (`user_invocable: false`) — you don't call it by name. It's meant
to be loaded automatically when an agent is operating inside a worktree (for example, by a
spawn step that writes `.claude/WORKTREE.md` and pulls this skill in). Once loaded, the
agent follows the build/test/cleanup lifecycle in `SKILL.md`.

It pairs naturally with a worktree-spawn step that creates the worktree and writes
`.claude/WORKTREE.md`, but it degrades gracefully on its own: if that context file is
missing it falls back to plain `git worktree` commands.

The build/test commands are intentionally generic — the skill tells the agent to use the
project's own documented commands (`README`, `Makefile`, `package.json` scripts, etc.)
rather than hard-coding any one stack.
