# codex-feedback-planning

A Claude Code skill that hands my plan to the **OpenAI Codex CLI** for a read-only second
opinion before I write any code.

## What it does

When a non-trivial plan is on the table (a big refactor, a multi-file feature, an
architecture change), this skill packages up the task, the plan, and the exact file paths
involved, then runs `codex exec` as an **external consultant**. Codex reads the real
codebase and critiques the plan: risks, breaking changes, missing edge cases, simpler
designs, bad sequencing. It makes **zero changes** — the prompt and sandbox keep it
read-only. Claude then summarizes Codex's feedback and asks me how I want to proceed.

To be clear about what's mine: I built the orchestration skill. **Codex itself is OpenAI's
tool** — I just drive it from Claude Code.

## Why I built it

I kept hitting the same trap: a single model writes a plan and reviews its own plan, so it
agrees with itself. The blind spots survive into the code. I wanted a genuinely different
model looking at my plan against the actual repo, not a rubber stamp from the same head
that wrote it.

Two things made it worth turning into a skill instead of a one-off command:

- **The stdin hang.** In a non-interactive shell, `codex exec` will sit forever at
  "Reading additional input from stdin..." unless you close stdin with `< /dev/null`. I
  lost real time to this before I pinned it down. The skill bakes in the fix so I never
  rediscover it.
- **Keeping it read-only.** A reviewer that "helpfully" edits your code is worse than no
  reviewer. The skill ships strict prompt templates plus the right sandbox flag so Codex
  stays an analyst, not an editor.

## How to use it

1. Install the Codex CLI once: `npm i -g @openai/codex && codex auth`
2. Drop this folder into `~/.claude/skills/codex-feedback-planning/`
3. Make a plan, then say **"codex review"**, **"ask codex"**, or **"get codex feedback"** —
   or accept the auto-suggestion after exiting plan mode on a multi-file plan.

Claude gathers the context, runs Codex read-only, and reports back a structured summary
(problems, alternatives, agreements, recommendation). I decide whether to keep my plan,
adopt Codex's suggestions, or go hybrid.

Pairs with my other delegation skills (`codex-task-delegator` for actual implementation in
an isolated worktree, `gemini-delegate` for the same shape on a different model). This one
is the read-only planning reviewer.
