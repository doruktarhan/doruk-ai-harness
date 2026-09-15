# codex-task-delegator

A Claude Code skill that hands off **implementation work** to the OpenAI Codex CLI when Claude is stuck or the task is too context-heavy, then reviews the result before anything touches the main branch.

## What it does

When Claude has burned a couple of attempts on the same bug, or a task needs more interconnected context than fits comfortably in one window, this skill orchestrates a clean handoff:

1. Spins up an **isolated git worktree** so Codex can write freely with zero risk to the main branch.
2. Packages the context Codex needs — the task, what Claude already tried and why it failed, the exact files, and the success criteria — using ready-made prompt templates.
3. Invokes `codex exec` non-interactively (with the two flags that actually matter so it doesn't hang).
4. Has Claude **review the diff and run the tests** in the worktree, then merge or discard.

It only orchestrates the external `codex` CLI — it doesn't reimplement Codex, and it makes no changes to my code on its own.

## Why I built it

I kept hitting the same wall: Claude would loop on a hard bug, each attempt slightly different, none landing. Switching to a different model is the obvious move, but doing it by hand was messy — copy-pasting context, worrying about Codex scribbling over working files, then trying to figure out what it actually changed.

So I codified the handoff. Two things make it worth it. First, **cross-model delegation**: a genuinely different model often breaks a loop that one model can't escape on its own. Second, **isolation**: Codex always works in a throwaway worktree, so a bad run costs me nothing — I review the diff, and merge only when the tests pass. The skill turns "ugh, let me try Codex" into a repeatable, low-risk move instead of a fiddly one-off.

It's the implementation half of a pair. Its sibling, `codex-feedback-planning`, runs Codex read-only to critique a *plan* before I write code. This one delegates the actual *building*.

## How to use it

Drop the folder into your skills directory:

```bash
cp -r codex-task-delegator ~/.claude/skills/
```

Make sure the Codex CLI is installed and authed:

```bash
npm i -g @openai/codex && codex auth
```

Then just ask Claude to delegate — "delegate this to codex", "let codex handle it", "codex fix" — or let it offer after it's failed a couple of attempts on its own. Claude creates the worktree, builds the prompt, runs Codex, reviews the diff with you, and merges only once the tests pass.
