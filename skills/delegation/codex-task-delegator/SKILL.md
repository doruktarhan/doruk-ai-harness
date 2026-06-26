---
name: codex-task-delegator
description: Delegate implementation tasks to OpenAI Codex CLI when Claude is stuck or the task is too context-heavy. Use when (1) Claude has failed to solve a bug or implement a feature after 2+ attempts, (2) a task requires deep codebase context that exceeds Claude's window, (3) the user explicitly says "delegate to codex", "let codex handle it", "hand off to codex", or "codex fix". Codex works in an isolated git worktree — Claude reviews the diff and merges after testing. Complementary to codex-feedback-planning (which reviews plans read-only); this skill delegates actual implementation work.
---

# Codex Task Delegator

Delegate implementation work to OpenAI Codex CLI in an isolated git worktree. Claude prepares context, Codex executes, Claude reviews and merges. This skill *orchestrates* the external `codex` CLI — it does not reimplement it.

**Relationship to codex-feedback-planning**: that skill is a read-only plan reviewer. This skill is for handing off implementation. Use codex-feedback-planning BEFORE coding to catch design issues. Use this skill DURING coding when stuck or overwhelmed.

## Prerequisites

```bash
which codex || echo "Install: npm i -g @openai/codex && codex auth"
```

## When to Delegate

Delegate when ANY of these apply:

- **Stuck after 2+ attempts** — same bug or feature keeps failing despite different approaches
- **Context-heavy task** — solution requires understanding many interconnected files that strain Claude's context
- **Different perspective needed** — Claude's approaches keep hitting the same wall
- **User requests it** — user explicitly asks to delegate

Do NOT delegate:
- First attempt at a problem (try it yourself first)
- Simple fixes, config changes, CRUD operations
- Tasks where Claude has a clear path forward

## Workflow

### Step 1: Create Isolated Worktree

Create a git worktree so Codex works in a sandbox. All changes are isolated until Claude explicitly merges them.

```bash
# From the project root
git worktree add .codex-worktree -b codex/task-description HEAD
```

Use a descriptive branch name based on the task (e.g., `codex/fix-race-condition`, `codex/refactor-auth-module`).

### Step 2: Gather Context

Collect ALL of the following before invoking Codex:

1. **Task description** — what needs to happen (the original user request)
2. **Claude's approach and what failed** — what was tried, what went wrong, error messages, test failures. This is critical — Codex needs to know what NOT to repeat
3. **Relevant file paths** — every file Codex needs to read or modify. Be exhaustive:
   - Files that failed to work in previous attempts
   - Dependencies and imports of those files
   - Related test files
   - Config files if relevant
4. **Success criteria** — how to verify the fix/feature works (test commands, expected behavior)
5. **Codex plan review feedback** — if `codex-feedback-planning` was used earlier, include its findings so Codex is aware of identified risks

### Step 3: Construct Prompt and Invoke

Build the prompt using templates from [references/prompt_templates.md](references/prompt_templates.md). Then invoke:

```bash
cd .codex-worktree
codex exec --sandbox workspace-write "<constructed-prompt>" < /dev/null
```

**Two flags are load-bearing:**

1. `--sandbox workspace-write` — replaces the deprecated `--full-auto`. Recent Codex versions warn on `--full-auto`; the swap is mechanical, same behavior.
2. `< /dev/null` — closes stdin. From `codex exec --help`: *"If stdin is piped and a prompt is also provided, stdin is appended as a `<stdin>` block."* Without this redirect Codex hangs at "Reading additional input from stdin..." waiting for EOF, especially in non-interactive shells (Bash tool, background tasks). Trivial probes may complete (the harness closes stdin on exit) but anything that does real work hangs at 0% CPU.

For very long prompts, write to a temp file:

```bash
cat > /tmp/codex_task.txt <<'PROMPT_EOF'
<constructed-prompt>
PROMPT_EOF
codex exec --sandbox workspace-write "$(cat /tmp/codex_task.txt)" < /dev/null
```

For long-running implementation runs, invoke in the background and watch:

```bash
( codex exec --sandbox workspace-write "$(cat /tmp/codex_task.txt)" \
    < /dev/null > /tmp/codex_out.txt 2>&1 ) &
PID=$!
for i in $(seq 1 480); do
  kill -0 $PID 2>/dev/null || { echo "exited after ${i}s"; break; }
  [ $((i % 30)) = 0 ] && echo "  ...running at ${i}s, output bytes=$(wc -c < /tmp/codex_out.txt)"
  sleep 1
done
kill -0 $PID 2>/dev/null && { kill -9 $PID; echo "HUNG — killed at 480s"; }
tail -250 /tmp/codex_out.txt
```

The `< /dev/null` redirect is required on the inner `codex exec` command, **not** the subshell — codex inherits stdin from its parent process, so the redirect must attach to the codex invocation itself.

### Step 4: Review Changes

After Codex finishes, review what it did:

```bash
cd .codex-worktree
git diff HEAD
```

Check for:
- Does the change address the actual problem?
- Are there unintended modifications to unrelated files?
- Does the approach look reasonable?
- Any obvious security issues or anti-patterns?

### Step 5: Test in Worktree

Run the project's test suite inside the worktree:

```bash
cd .codex-worktree
# Run relevant tests (project-specific command)
```

If tests fail, either:
- **Re-invoke Codex** with the test failure output as additional context
- **Fix minor issues** yourself in the worktree
- **Abandon** if the approach is fundamentally wrong

### Step 6: Merge or Discard

**If tests pass and changes look good:**

```bash
# From the main working directory
git merge codex/task-description
git worktree remove .codex-worktree
git branch -d codex/task-description
```

**If changes are bad:**

```bash
git worktree remove --force .codex-worktree
git branch -D codex/task-description
```

Report to the user what Codex did, what was reviewed, and the outcome.

## Auto-Trigger Behavior

When Claude has failed 2+ attempts at the same task, suggest:

> "I've tried [N] approaches for this and haven't been able to solve it. Would you like me to delegate this to Codex? It will work in an isolated worktree so we can review the changes before merging."

Wait for user confirmation. Never auto-delegate without asking.

## Handling Codex Failures

**Codex hangs at "Reading additional input from stdin..." with 0% CPU:**
- stdin not closed. Add `< /dev/null` to the codex invocation. This is the single most common failure mode in non-interactive shells.

**`--full-auto` deprecation warning:**
- Swap to `--sandbox workspace-write`. Same behavior.

**Codex didn't solve it:**
- Provide more context (error messages, stack traces from Codex's attempt)
- Break the task into smaller pieces and delegate each separately
- Try interactive mode: `cd .codex-worktree && codex` then provide context conversationally

**Codex broke other things:**
- Discard the worktree (zero risk to main branch)
- Re-invoke with explicit constraints about what NOT to change

**Codex misunderstood:**
- Add concrete examples of expected input/output
- Show what the code does now vs what it should do
- Reference specific test cases that should pass

## Complementary Skill Usage

```
Plan phase:  codex-feedback-planning  →  Read-only plan review
                                          "Here are problems with your approach..."

Build phase: codex-task-delegator     →  Implements in isolated worktree
                                          "Here's the fix, tested in worktree"
```

If `codex-feedback-planning` identified issues earlier, include that feedback in the delegation prompt so Codex avoids those pitfalls.
