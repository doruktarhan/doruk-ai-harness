# gemini-delegate

A Claude Code skill that delegates work to the **Google Gemini CLI** as a second pair of hands — either a read-only **consultant** that critiques a plan, or an **implementer** that writes code in an isolated git worktree.

## What it does

Wires the Gemini CLI into the agent's workflow with two modes:

- **Consultant** (`--approval-mode plan`) — Gemini reads your code and plan and produces written critique. It physically cannot write files; the CLI enforces read-only.
- **Implementer** (`--yolo`) — Gemini gets full write access, but only inside a throwaway git worktree. You review the diff and merge (or discard with zero risk to `main`).

The agent auto-picks the mode from your phrasing ("gemini review" vs "gemini fix"), and asks when it's ambiguous. It ships with prompt templates for both modes so the hand-off prompt is structured instead of improvised.

This skill **orchestrates** the external Gemini CLI. I didn't build Gemini — I built the harness around it: mode selection, worktree isolation, the load-bearing invocation flags, and the review/merge loop.

## Why I built it

I kept hitting two situations. First, I'd finish a non-trivial plan and want a second set of eyes from a *different* model before writing any code — Claude reviewing its own plan has a blind spot. Second, I'd get genuinely stuck on a bug after a few attempts and want to hand it off cleanly instead of thrashing.

Doing this by hand was fiddly. The Gemini CLI hangs silently at 0% CPU in non-interactive shells if you forget to close stdin (`< /dev/null`), and "let another model edit my repo" is terrifying without isolation. So I encoded the safe pattern once: consultant mode can't touch files, implementer mode is sandboxed in a worktree, and the diff always gets reviewed before it reaches `main`. Now delegating is a sentence, not a checklist.

It's deliberately the same shape as my Codex-based delegators — same consultant/implementer split, different model — so I can get cross-model second opinions or pick whichever model fits the task.

## How to use it

1. Install the Gemini CLI: `npm i -g @google/gemini-cli`
2. Drop this folder into your skills directory: copy `gemini-delegate/` into `~/.claude/skills/`.
3. In a Claude Code session, just say what you want:
   - "ask gemini to review this plan" → consultant mode
   - "delegate this to gemini" / "let gemini fix it" → implementer mode (worktree, then you review the diff)
   - "get a second opinion from gemini" → consultant mode, independent take

The agent gathers context, builds the prompt from the bundled templates, runs Gemini, and reports back. In implementer mode nothing reaches your main branch until you've seen the diff and tests pass.

## Files

- `SKILL.md` — the skill definition (modes, workflows, invocation flags, troubleshooting).
- `references/consultant_templates.md` — read-only review prompt templates.
- `references/implementer_templates.md` — worktree implementation prompt templates.
