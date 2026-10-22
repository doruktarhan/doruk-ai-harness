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

Every `codex exec` goes through the wrapper, usually as a background Bash whose exit wakes you:

```bash
~/.claude/skills/codex/scripts/codex-run.sh MODEL EFFORT SANDBOX WORKDIR PROMPT_FILE OUT [MAX_S=1500] [START_S=120] [QUIET_S=600]
```

It closes stdin, caps wall time, kills a run with no session id after START_S or no output
for QUIET_S, prints a heartbeat a minute, and ends OUT with `CODEX_EXIT=<rc>` or
`CODEX_KILLED=<reason>` (exit 124). macOS has no `timeout`, and the Bash tool's `timeout`
is ignored under `run_in_background`, so the wrapper is the only cap.

Then read the mode's reference for model pins, the prompt shape, and troubleshooting:

- Consultant: [references/consultant.md](references/consultant.md)
- Implementer: [references/implementer.md](references/implementer.md)

## Done when

- **Consultant** — Codex's critique is summarized for the user as problems, alternatives,
  agreements, and a recommendation, and the user has chosen how to proceed.
- **Implementer** — the worktree diff has been reviewed, the project's tests have been run
  in the worktree, and the branch is either merged or discarded with the worktree removed.
