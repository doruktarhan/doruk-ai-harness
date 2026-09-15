# codex

A Claude Code skill that drives the **OpenAI Codex CLI** either as a read-only second opinion
on my plans or as an implementer working in a throwaway git worktree. One skill, two modes —
it replaces the old `codex-feedback-planning` / `codex-task-delegator` pair.

## What it does

`SKILL.md` is a router: it checks the CLI is installed, picks the mode from the task, and
hands off to one of two references that carry the operational detail.

- **Consultant** (`--sandbox read-only`) — packages the task, the plan or spec or diff, and the
  exact file paths, then has Codex critique it against the real codebase. Zero writes; the
  sandbox enforces that, not the prompt. Claude reports back problems, alternatives,
  agreements, and a recommendation.
- **Implementer** (`--sandbox workspace-write`) — spins up an isolated worktree, packages the
  task plus what already failed plus the success criteria, lets Codex build, then reviews the
  diff and runs the tests before merging or discarding.

It only orchestrates the external `codex` CLI. **Codex itself is OpenAI's tool.**

## Why I built it

One model writing a plan and then reviewing its own plan just agrees with itself, and the blind
spots survive into the code. And when Claude loops on a hard bug, switching models is the
obvious move but was fiddly by hand — copy-pasting context, worrying about a "helpful" editor
scribbling over working files, then reconstructing what changed.

Three things earned a skill rather than a one-off command:

- **The stdin hang.** In a non-interactive shell `codex exec` sits forever at "Reading
  additional input from stdin..." unless stdin is closed with `< /dev/null`. I lost real time
  to this. The skill bakes in the fix so I never rediscover it.
- **The model pin.** `~/.codex/config.toml` defaults to whatever I last set interactively, so an
  unpinned call silently retiers the work. Reviews pin Sol (Astra for architecture, backend, and
  hard specs); labor pins Luna at max effort.
- **Isolation.** Implementation always lands in a worktree, so a bad run costs nothing — I read
  the diff and merge only when the tests pass.

## How to use it

Install the CLI once, then symlink or copy the folder into your skills directory:

```bash
npm i -g @openai/codex && codex auth
ln -s "$PWD/codex" ~/.claude/skills/codex
```

Say **"codex review"**, **"ask codex"**, **"delegate to codex"**, or **"codex fix"** and it runs.
It also offers itself unprompted after a non-trivial plan lands or after two failed attempts on
the same task.

Its sibling `gemini-delegate` is the same shape on Google's CLI, for when a third model is
wanted.
