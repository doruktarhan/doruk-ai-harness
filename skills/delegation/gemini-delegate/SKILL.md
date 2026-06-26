---
name: gemini-delegate
description: Delegate work to the Google Gemini CLI — either as an implementer (worktree + yolo) or a read-only consultant (plan mode). Use when (1) the agent has failed 2+ attempts on the same task, (2) the user explicitly says "delegate to gemini", "ask gemini", "gemini review", "gemini fix", "let gemini handle it", (3) a second opinion from a different model is wanted on a plan, implementation, or design, (4) after a non-trivial plan is created and review is needed before coding. The agent auto-selects implementer vs consultant mode from the task; if ambiguous, asks the user. Same shape as a Codex-based delegator — different model.
---

# Gemini Delegate

Delegate to the Google Gemini CLI in one of two modes. The agent picks the mode from the task; the user can override.

| Mode | Flag | What it does |
|------|------|--------------|
| **Consultant** | `--approval-mode plan` | Read-only critique of plans, architecture, or code. No file writes. |
| **Implementer** | `--yolo` | Full write access in an isolated git worktree. Bypasses all approvals. |

This skill orchestrates the external Google Gemini CLI — it does not bundle or replace it. Install the CLI separately (see Prerequisites).

## Prerequisites

```bash
which gemini || echo "Install: npm i -g @google/gemini-cli"
```

For plan-mode failures, older Gemini versions required `experimental.plan: true` in `~/.gemini/settings.json`:

```json
{ "experimental": { "plan": true } }
```

## Mode Selection

The agent decides from the task. When ambiguous, ask the user.

| Trigger | Mode |
|---------|------|
| "review", "feedback", "critique", "analyze", "second opinion" on a plan | Consultant |
| "fix", "implement", "build", "refactor", "delegate", "hand off" | Implementer |
| Reviewing a plan before coding | Consultant |
| Stuck after 2+ attempts | Implementer (after asking) |
| User says "ask gemini" with no other signal | Ask |

Do NOT delegate to implementer mode for:
- First attempt at a problem (try directly first)
- Trivial fixes, config changes, one-line tweaks
- Tasks where there is already a clear path forward

## Consultant Mode (Read-Only Review)

Gemini reads files but cannot modify anything. `--approval-mode plan` enforces this at the CLI level.

### Workflow

**1. Gather context** before invoking:
- Task description (the original user request)
- The plan being reviewed (steps, files to change, approach)
- All file paths Gemini needs to read — be exhaustive so Gemini does not search the repo

**2. Build the prompt** using templates in [references/consultant_templates.md](references/consultant_templates.md).

**3. Invoke**:

```bash
cd <project-root>
gemini -p "<constructed-prompt>" --approval-mode plan < /dev/null
```

For long prompts, write to a temp file first:

```bash
cat > /tmp/gemini_review.txt <<'PROMPT_EOF'
<constructed-prompt>
PROMPT_EOF
gemini -p "$(cat /tmp/gemini_review.txt)" --approval-mode plan < /dev/null
```

**Two flags are load-bearing:**

1. `--approval-mode plan` — enforces read-only. Without it Gemini may attempt edits even if the prompt says not to.
2. `< /dev/null` — closes stdin. Without it Gemini can hang at startup in non-interactive shells (an agent's Bash tool, background tasks) waiting for EOF. Trivial probes may complete because the harness closes stdin on exit, but real work hangs at 0% CPU.

**4. Present findings** to the user in this structure:

```
## Gemini Review Summary

### Problems Identified
- [items]

### Alternative Approaches Suggested
- [items]

### Agreements with Current Plan
- [items]

### Recommendation
[Synthesis — keep plan as-is, adopt suggestions, or hybrid]
```

**5. Ask the user** how to proceed.

## Implementer Mode (Worktree + Yolo)

Gemini works in an isolated git worktree with full write access via `--yolo`. All changes stay sandboxed until explicitly merged.

### Workflow

**1. Create the worktree**:

```bash
git worktree add .gemini-worktree -b gemini/task-description HEAD
```

Use a descriptive branch name (`gemini/fix-race-condition`, `gemini/refactor-auth-module`).

Gemini also supports `-w <branch>` to create a worktree automatically, but prefer the manual form above — it gives explicit control over the branch name and the merge step.

**2. Gather context** — collect ALL of:
- Task description (original user request)
- What was already tried and why it failed — Gemini must not repeat failed approaches
- Every file path Gemini may need to read or modify (be exhaustive, include dependencies, related tests, config)
- Success criteria — exact test commands, expected behavior
- Prior consultant findings — if a consultant review was done earlier, paste its findings under "Known Risks"

**3. Build the prompt** using templates in [references/implementer_templates.md](references/implementer_templates.md).

**4. Invoke**:

```bash
cd .gemini-worktree
gemini -p "<constructed-prompt>" --yolo < /dev/null
```

For long prompts:

```bash
cat > /tmp/gemini_task.txt <<'PROMPT_EOF'
<constructed-prompt>
PROMPT_EOF
gemini -p "$(cat /tmp/gemini_task.txt)" --yolo < /dev/null
```

For long-running implementations, invoke in the background and watch:

```bash
( cd .gemini-worktree && gemini -p "$(cat /tmp/gemini_task.txt)" --yolo \
    < /dev/null > /tmp/gemini_out.txt 2>&1 ) &
PID=$!
for i in $(seq 1 480); do
  kill -0 $PID 2>/dev/null || { echo "exited after ${i}s"; break; }
  [ $((i % 30)) = 0 ] && echo "  ...running at ${i}s, output bytes=$(wc -c < /tmp/gemini_out.txt)"
  sleep 1
done
kill -0 $PID 2>/dev/null && { kill -9 $PID; echo "HUNG — killed at 480s"; }
tail -250 /tmp/gemini_out.txt
```

The `< /dev/null` redirect must attach to the inner `gemini` command, not the subshell — Gemini inherits stdin from its parent process.

**Two flags are load-bearing:**

1. `--yolo` — bypasses every approval prompt. Equivalent to `--approval-mode yolo`. Without it Gemini will block waiting for confirmation on each tool call.
2. `< /dev/null` — same reason as consultant mode. Required in non-interactive shells.

**5. Review changes**:

```bash
cd .gemini-worktree
git diff HEAD
```

Check:
- Does the change address the actual problem?
- Any unintended modifications to unrelated files?
- Does the approach look reasonable?
- Any obvious security issues or anti-patterns?

**6. Test in the worktree** with the project's test command. If tests fail:
- Re-invoke Gemini with the test failure output as additional context
- Fix minor issues yourself in the worktree
- Abandon if the approach is fundamentally wrong

**7. Merge or discard**:

```bash
# Tests pass and changes look good — from the main working directory:
git merge gemini/task-description
git worktree remove .gemini-worktree
git branch -d gemini/task-description

# Changes are bad — discard with zero risk to main:
git worktree remove --force .gemini-worktree
git branch -D gemini/task-description
```

Report to the user what Gemini did, what was reviewed, and the outcome.

## Auto-Trigger Behavior

**As consultant**, after a non-trivial plan is created (3+ files or architectural changes):

> "Would you like me to get Gemini's feedback on this plan before proceeding?"

**As implementer**, after 2+ failed attempts at the same task:

> "I've tried [N] approaches and haven't been able to solve it. Want me to delegate this to Gemini in an isolated worktree? We can review the changes before merging."

Always wait for user confirmation. Never auto-invoke.

## Cross-Model Delegation

This skill pairs naturally with a Codex-based delegator (same shape, OpenAI's CLI):

| Role | Read-only | Worktree implementation |
|------|-----------|-------------------------|
| Codex CLI | Plan review | Implementation |
| Gemini CLI (this) | Plan review | Implementation |

Reach for Gemini when:
- A second opinion from a different model is wanted (another model already weighed in)
- Comparing approaches across providers before committing
- The task plays to Gemini's strengths (long-context analysis, large file sets)

## Troubleshooting

- **`gemini: command not found`** → `npm i -g @google/gemini-cli`
- **Gemini hangs at 0% CPU** → stdin not closed. Add `< /dev/null` to the inner gemini invocation. This is the single most common failure mode in non-interactive shells.
- **Plan mode rejected on older versions** → add `{"experimental":{"plan":true}}` to `~/.gemini/settings.json`.
- **Gemini ignored the read-only instruction** → make sure `--approval-mode plan` is on the command line, not just in the prompt text. Plan-mode is enforced by the CLI, not the prompt.
- **Gemini didn't solve it** → provide more context (errors, stack traces from its attempt), shrink the scope and delegate piecewise, or try interactive mode: `cd .gemini-worktree && gemini`
- **Gemini broke unrelated things** → discard the worktree (no risk to main), re-invoke with an explicit "DO NOT TOUCH" list
- **Gemini misunderstood the task** → add concrete input/output examples, reference specific test cases that should pass
- **Prompt too long for the CLI arg** → write to a temp file, pass via `"$(cat /tmp/foo.txt)"` (NOT a shell pipe — Gemini needs the prompt as an argument)
