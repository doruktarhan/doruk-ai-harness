---
name: codex-feedback-planning
description: Delegate plan review and design feedback to OpenAI Codex CLI as an external consultant. Use when (1) a plan or implementation strategy has just been created for a large refactor or feature, (2) the user explicitly asks for Codex feedback/review on a plan, (3) the user says "codex review", "ask codex", "delegate to codex", or "get codex feedback", or (4) after exiting plan mode on non-trivial multi-file plans. Codex acts as a read-only consultant — it analyzes and critiques but makes NO changes to the codebase.
---

# Codex Feedback Planning

Orchestrate the OpenAI Codex CLI as a second-opinion reviewer. Codex receives the task,
the plan, and relevant file paths, then provides independent critique without modifying
code. This is a read-only consultation: a different model reads your plan against the real
codebase and tells you what it would break.

## Prerequisites

Verify the Codex CLI is installed before first use:

```bash
which codex || echo "Codex not installed. Run: npm i -g @openai/codex && codex auth"
```

## Workflow

### Step 1: Gather Context

Collect these items BEFORE invoking Codex:

1. **Task description** — what the user wants to accomplish (the original request)
2. **The plan** — the proposed implementation plan (steps, files to change, approach)
3. **Relevant paths** — list specific directories and files the plan touches. Be exhaustive so Codex does not need to explore the repo

To identify relevant paths, use the plan's file list plus any imports/dependencies those files reference. Include:
- Files to be modified or created
- Key interfaces, types, or contracts those files depend on
- Test files related to the changes
- Configuration files affected

### Step 2: Construct the Codex Prompt

Build the prompt using the template in [references/prompt_templates.md](references/prompt_templates.md).

Key rules for the prompt:
- **State the task objectively** — describe what needs to happen, not why a particular approach was chosen
- **Include the full plan** — Codex needs to see the proposed steps to critique them
- **List all relevant file paths** — so Codex can read them without searching the whole repo
- **Explicitly instruct no modifications** — Codex must only analyze and report

### Step 3: Invoke Codex

Run via the Bash tool:

```bash
cd <project-root>
codex exec --sandbox workspace-write "<constructed-prompt>" < /dev/null
```

**Two flags are load-bearing here:**

1. `--sandbox workspace-write` — replaces the deprecated `--full-auto`. Codex 0.128+ warns on `--full-auto` but the swap is mechanical.
2. `< /dev/null` — closes stdin. From `codex exec --help`: *"If stdin is piped and a prompt is also provided, stdin is appended as a `<stdin>` block."* Without this redirect, Codex will sit forever at "Reading additional input from stdin..." waiting for EOF, especially when run from a non-interactive shell (Bash tool, background task). The trivial probe `codex exec ... "READY"` may complete because the harness closes stdin on exit, but anything that does real work hangs.

If the prompt is long, write it to a temp file and read it back as the argument:

```bash
cat > /tmp/codex_prompt.txt <<'PROMPT_EOF'
<the prompt>
PROMPT_EOF
codex exec --sandbox workspace-write "$(cat /tmp/codex_prompt.txt)" < /dev/null
```

For long-running reviews invoke in the background and poll the output file:

```bash
( codex exec --sandbox workspace-write "$(cat /tmp/codex_prompt.txt)" \
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

The `< /dev/null` redirect is required on the inner command, **not** the subshell — codex inherits stdin from its parent, so the redirect must be on the codex invocation itself.

### Step 4: Present Findings

After Codex responds:

1. **Summarize** Codex's feedback in a structured format
2. **Highlight** any problems, risks, or alternative approaches Codex identified
3. **Compare** Codex's suggestions against the original plan
4. **Recommend** whether to adjust the plan based on Codex's input
5. **Ask the user** how they want to proceed — keep original plan, adopt Codex's suggestions, or hybrid

Format the output as:

```
## Codex Review Summary

### Problems Identified
- [list items]

### Alternative Approaches Suggested
- [list items]

### Agreements with Current Plan
- [list items]

### Recommendation
[Synthesis of whether/how to adjust the plan]
```

## Auto-Trigger Behavior

After exiting plan mode for non-trivial plans (3+ files or architectural changes), suggest:

> "This plan touches multiple files/systems. Would you like me to get Codex's feedback on potential issues before proceeding?"

Wait for user confirmation before invoking Codex. Never auto-invoke without asking.

## Troubleshooting

- **Codex not found**: `npm i -g @openai/codex && codex auth`
- **Prompt too long**: Write to temp file, pass via `"$(cat …)"` (NOT shell pipe — codex needs the prompt as an argument)
- **Codex hangs at "Reading additional input from stdin..." with 0% CPU**: stdin not closed. Add `< /dev/null` to the codex invocation. This is the single most common failure mode in non-interactive shells.
- **`--full-auto` deprecation warning**: swap to `--sandbox workspace-write` (same behavior).
- **Codex times out**: Break the review into smaller focused questions (e.g., "Review only the database migration part")
- **Codex makes changes despite instructions**: This means the prompt was not strict enough. Re-run with the reinforced template from references/prompt_templates.md
