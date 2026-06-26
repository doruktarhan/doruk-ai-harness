---
name: worktree-init
description: Create an isolated git worktree for a branch, copy untracked local files (.env, agent config, IDE rules) that don't travel with git, and bootstrap the project environment so the worktree is ready to run.
user_invocable: true
metadata:
  author: doruktarhan
  version: "1.0.0"
  domain: devops
  triggers: worktree, worktree init, new worktree, branch worktree
  role: utility
  scope: setup
  output-format: terminal
---

# Worktree Init

Set up an isolated git worktree for a branch with all local files and dependencies ready to go.

A fresh `git worktree add` gives you the tracked files only. Two things break: the untracked
local files that never get committed (`.env`, IDE rules, agent config) are missing, and the
environment (virtualenv, installed packages) isn't built. This skill does the `git worktree add`,
then copies the gitignored files across and bootstraps the environment, so the new worktree
actually runs instead of erroring on a missing secret or an empty venv.

## When to use it

- Starting work on a branch that needs isolation from your current checkout.
- Running multiple agents or tasks in parallel, each in its own tree, without them stepping on
  each other's working directory.
- Any time `git worktree add` alone would leave you with a tree that can't run because the
  untracked local files or the environment aren't there.

## What it does

1. **Ask which branch.** Default to the current branch. If a branch name is passed as an
   argument, use it and skip the prompt. For a new branch, create it with `-b`.
2. **Ask for the worktree path.** Default to a sibling directory outside the repo, e.g.
   `<parent-of-repo>/<repo-name>-worktrees/<branch-short-name>`. Keeping worktrees outside the
   repo avoids nesting one git tree inside another.
3. **Create the worktree.** Run `git worktree add <path> <branch>` (add `-b <branch>` when the
   branch is new).
4. **Copy untracked local files** that don't travel with git. Detect which of these exist in the
   source checkout and copy each one that's present:
   - Env files: `.env`, `.env.local`, and any nested ones (e.g. `<service>/.env.local`).
   - Agent / tooling config and notes folders that are gitignored.
   - IDE rule and skill folders (e.g. `.cursor/rules/`, `.cursor/skills/`, local `.claude/`
     overrides).
   - Anything else the user names as a needed local file.

   Only copy paths that actually exist; skip the rest silently. Ask the user if you're unsure
   whether a gitignored path should travel.
5. **Bootstrap the environment.** Detect the project type and run the right install in the
   worktree (examples: `uv sync` / `uv sync --extra dev` for a uv-managed Python project,
   `python -m venv .venv && pip install -e .` for plain Python, `npm install` for Node). If the
   environment lives in a subdirectory, run it there.
6. **Confirm.** Print the final worktree path and report that it's ready, including the bootstrap
   command that ran.

## Detecting what to copy

Use git to find the untracked/ignored files instead of guessing, then filter to the ones that
matter:

```bash
# list ignored files in the source checkout
git -C <source-repo> status --ignored --porcelain | awk '/^!!/ {print $2}'
```

From that list, copy env files, agent/notes config, and IDE rule folders. Don't blindly copy
everything ignored — large build artifacts (`node_modules/`, `.venv/`, `dist/`, `__pycache__/`)
should be rebuilt by the bootstrap step, not copied.

## Usage

```
/worktree-init
/worktree-init feature/my-branch
```

If a branch name is provided as an argument, skip the branch prompt and use it directly.

## Cleanup

When the work is done and merged, remove the worktree so it doesn't linger:

```bash
git worktree remove <path>      # or: git worktree remove --force <path> if it has changes
git worktree prune              # tidy up stale administrative entries
```
