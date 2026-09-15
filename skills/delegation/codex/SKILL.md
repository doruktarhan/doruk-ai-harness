---
name: codex
description: Delegate to OpenAI Codex CLI as a read-only consultant (plan/spec/diff review) or a worktree implementer. Triggers "ask codex", "codex review", "codex feedback", "delegate to codex", "codex fix", "let codex handle it"; also after a non-trivial plan or 2+ failed attempts.
---

# Codex

Drive the external OpenAI Codex CLI in one of two modes. This skill orchestrates `codex`;
it does not replace it.

| Mode | Sandbox | What it does |
|------|---------|--------------|
| **Consultant** | `--sandbox read-only` | Critiques a plan, spec, or diff against the real repo. No writes. |
| **Implementer** | `--sandbox workspace-write` | Implements in an isolated git worktree; Claude reviews the diff and merges. |

## Preflight

```bash
which codex || echo "Install: npm i -g @openai/codex && codex auth"
```

`codex auth` is interactive — if auth is stale, hand that command to the user.

## Picking a mode

| Signal | Mode |
|--------|------|
| "review", "feedback", "critique", "second opinion" on a plan, spec, or diff | Consultant |
| A non-trivial plan exists and no code is written yet | Consultant |
| "fix", "implement", "build", "refactor", "let codex handle it" | Implementer |
| Claude failed 2+ attempts on the same task | Implementer |
| "ask codex" with no other signal | Ask the user which |

Skip implementer mode on a first attempt, a trivial fix, or a task with a clear path forward.

## Invoking

When the user asked for Codex, run it. Consultant mode is read-only and implementer mode is
confined to a throwaway worktree, so neither needs a confirmation turn.

When this skill self-triggers unprompted — a plan just landed, or Claude has failed twice —
offer in one line and proceed if the user agrees:

> "Want Codex to review this plan first?" / "Want me to hand this to Codex in a worktree?"

Then read the mode's reference for model pins, invocation patterns, the background-run
recipe, and troubleshooting:

- Consultant: [references/consultant.md](references/consultant.md)
- Implementer: [references/implementer.md](references/implementer.md)

## Done when

- **Consultant** — Codex's critique is summarized for the user as problems, alternatives,
  agreements, and a recommendation, and the user has chosen how to proceed.
- **Implementer** — the worktree diff has been reviewed, the project's tests have been run
  in the worktree, and the branch is either merged or discarded with the worktree removed.
