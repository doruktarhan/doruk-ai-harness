# Codex Implementer Mode

Codex implements in an isolated git worktree. Claude prepares the context, Codex writes, Claude
reviews the diff and tests before anything reaches the main branch. A bad run costs nothing.

## 1. Create the worktree

```bash
# from the project root
git worktree add .codex-worktree -b codex/task-description HEAD
```

Name the branch after the task: `codex/fix-race-condition`, `codex/refactor-auth-module`.

## 2. Gather context

- **Task** — the original request.
- **What was tried and why it failed** — previous approaches, error messages, test failures.
  Codex needs to know what not to repeat.
- **File paths** — exhaustive: files that failed before, their dependencies and imports,
  related tests, relevant config.
- **Success criteria** — the exact test commands and expected behavior.
- **Prior consultant findings** — if a Codex review ran earlier, paste them under "Known Risks"
  so the implementation addresses them. See [consultant.md](consultant.md).

## 3. Build the prompt

Every prompt opens with "You are working in a git worktree. You have full write access." and
lists file paths explicitly so Codex never greps the whole repo. Pick the shape that fits:

**Bug fix after failed attempts**

```
## Task
Fix: {bug_description}

## What Has Been Tried (do not repeat these)
{previous_attempts_and_why_they_failed}

## Error Output / Stack Traces
{error_output}

## Files to Focus On
{file_list_with_brief_descriptions}

## Success Criteria
{test_commands_and_expected_behavior}

## Constraints
- Only modify the files above unless the root cause is elsewhere
- Run the test command to verify
- Keep changes minimal — fix the bug, do not refactor
```

**Feature implementation (context-heavy)** — task, architecture context, approach guidance,
`## Known Risks (from prior plan review)` when a review ran, file list, success criteria.
Constraints: follow existing project patterns, only add files when clearly needed, run tests.

**Refactor** — task, why the current structure is wrong, what was tried, file list, plus
behavioral requirements: external behavior must not change and these tests must still pass.
Constraints: preserve existing tests, keep the public API, stay focused on the stated goal.

**Research + fix (root cause unknown)** — problem, observable symptoms, investigation done so
far, remaining hypotheses, suspected files to start from. Deliverable: identify the root cause,
implement the fix, leave a comment at the fix site explaining the cause, run the tests.

## 4. Invoke

```bash
cd .codex-worktree
codex exec -m gpt-5.6-luna -c model_reasoning_effort="max" --sandbox workspace-write "<prompt>" < /dev/null
```

Labor runs on Luna at max effort. The pin is mandatory: `~/.codex/config.toml` inherits whatever
was last set interactively, so an unpinned call silently retiers the task. Sol and Astra are
review models and never run labor — see [consultant.md](consultant.md).

`--sandbox workspace-write` replaces the deprecated `--full-auto`; the swap is mechanical, same
behavior.

`< /dev/null` closes stdin. Per `codex exec --help`, a piped stdin plus a prompt argument makes
Codex append stdin as a `<stdin>` block, so without the redirect it waits at "Reading additional
input from stdin..." for an EOF that never comes. Trivial probes can still finish because the
harness closes stdin on exit; real work hangs at 0% CPU.

Long prompts go through a temp file, passed as an argument (not piped):

```bash
cat > /tmp/codex_task.txt <<'PROMPT_EOF'
<prompt>
PROMPT_EOF
codex exec -m gpt-5.6-luna -c model_reasoning_effort="max" --sandbox workspace-write "$(cat /tmp/codex_task.txt)" < /dev/null
```

Long runs go in the background with polling:

```bash
( cd .codex-worktree && codex exec -m gpt-5.6-luna -c model_reasoning_effort="max" --sandbox workspace-write "$(cat /tmp/codex_task.txt)" \
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

The redirect attaches to the inner `codex exec`, not the subshell — codex inherits stdin from its
parent.

## 5. Review the diff

```bash
cd .codex-worktree
git diff HEAD
```

Check that the change addresses the actual problem, that unrelated files were left alone, that
the approach is reasonable, and that there are no obvious security issues or anti-patterns.

## 6. Test in the worktree

Run the project's test command inside `.codex-worktree`. On failure, either re-invoke Codex with
the failure output as added context, fix small issues in the worktree yourself, or abandon if the
approach is fundamentally wrong.

## 7. Merge or discard

Tests pass and the diff looks good — from the main working directory:

```bash
git merge codex/task-description
git worktree remove .codex-worktree
git branch -d codex/task-description
```

Changes are bad — discard the worktree with `git worktree remove --force .codex-worktree`, then
force-delete the unmerged branch with `git branch -D codex/task-description`. Main is untouched
either way.

Report what Codex did, what was reviewed, and the outcome.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `codex: command not found` | `npm i -g @openai/codex && codex auth` |
| Hangs at "Reading additional input from stdin...", 0% CPU | stdin not closed — add `< /dev/null` to the codex invocation. Most common failure in non-interactive shells. |
| `--full-auto` deprecation warning | Use `--sandbox workspace-write`; same behavior. |
| Prompt too long | Temp file plus `"$(cat …)"` — codex needs the prompt as an argument, not on a pipe. |
| Codex did not solve it | Add the errors and stack traces from its attempt, split the task and delegate piecewise, or go interactive: `cd .codex-worktree && codex`. |
| Codex broke unrelated things | Discard the worktree, re-invoke with an explicit list of what not to touch. |
| Codex misunderstood | Give concrete input/output examples, contrast current vs desired behavior, name the test cases that must pass. |
