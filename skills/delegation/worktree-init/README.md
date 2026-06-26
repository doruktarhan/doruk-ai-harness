# worktree-init

A skill that spins up a ready-to-run git worktree in one shot: it creates the worktree, copies
the untracked local files that git won't move for you, and bootstraps the environment.

## What it does

Given a branch (or the current one), it runs `git worktree add` into an isolated sibling
directory, then copies across the gitignored files a fresh worktree is missing (`.env`, agent and
IDE config, local rule folders), and runs the project's install step so the tree actually works.
It also tells you how to tear the worktree down when you're done.

## Why I built it

I run multiple agents and tasks in parallel, each on its own branch, so I lean on git worktrees
hard. The problem is that `git worktree add` only gives you the tracked files. Every new tree was
missing my `.env` and my local config, and had no virtualenv, so the first thing I did in every
fresh worktree was the same boring dance: copy a handful of gitignored files over by hand and
re-run the install. I automated exactly that dance so a new worktree is usable the moment it's
created instead of erroring on a missing secret or an empty environment.

## How to use it

Copy this folder into your skills directory:

```bash
cp -r worktree-init ~/.claude/skills/
```

Then invoke it:

```
/worktree-init                    # uses the current branch
/worktree-init feature/my-branch  # uses the branch you name
```

It'll ask for the worktree path (with a sensible default outside the repo), copy your local
files, bootstrap the environment, and print the ready-to-use path.

Adjust the copy list and the bootstrap command in `SKILL.md` to match your stack — the defaults
cover `.env` files, IDE rule folders, and common Python/Node installs.
