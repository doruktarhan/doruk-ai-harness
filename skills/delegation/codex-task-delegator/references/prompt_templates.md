# Codex Task Delegation Prompt Templates

## Template 1: Bug Fix (after failed attempts)

```
You are working in a git worktree. You have full write access to implement a fix.

## Task

Fix the following bug: {bug_description}

## What Has Been Tried (DO NOT repeat these approaches)

{previous_attempts_with_reasons_they_failed}

## Error Output / Stack Traces

{error_output}

## Files to Focus On

These are the relevant files — start here, do not search the whole repo:
{file_list_with_brief_descriptions}

## Success Criteria

The fix is correct when:
{test_commands_and_expected_behavior}

## Constraints

- Only modify files listed above unless you discover a root cause elsewhere
- Run the test command after your fix to verify
- Keep changes minimal — fix the bug, don't refactor
```

## Template 2: Feature Implementation (context-heavy)

```
You are working in a git worktree. You have full write access to implement this feature.

## Task

{feature_description}

## Architecture Context

{relevant_architecture_overview}

## Approach Guidance

{plan_or_approach_notes}

{if_codex_feedback_planning_was_used}
## Known Risks (from prior plan review)

A plan review identified these concerns:
{codex_feedback_planning_findings}

Address or mitigate these in your implementation.
{end_if}

## Files to Work With

These are the relevant files — start here, do not search the whole repo:
{file_list_with_brief_descriptions}

## Success Criteria

{test_commands_and_expected_behavior}

## Constraints

- Follow existing code patterns and conventions in the project
- Only modify files listed above unless a new file is clearly needed
- Run tests after implementation
```

## Template 3: Refactor / Complex Change

```
You are working in a git worktree. You have full write access to implement this refactor.

## Task

{refactor_description}

## Why This Refactor

{motivation — what's wrong with current structure}

## What Was Tried

{previous_approaches_and_why_they_failed}

## Files Involved

These are the relevant files — start here, do not search the whole repo:
{file_list_with_brief_descriptions}

## Behavioral Requirements

The refactor must NOT change external behavior. These tests must continue to pass:
{test_commands}

## Constraints

- Preserve all existing tests
- Keep the same public API / interfaces
- Changes should be minimal and focused on the stated goal
```

## Template 4: Research + Fix (when root cause is unknown)

```
You are working in a git worktree. You have full write access.

## Task

Investigate and fix: {problem_description}

## Symptoms

{observable_symptoms}

## Investigation Done So Far

{what_claude_already_checked_and_found}

## Hypotheses

{remaining_hypotheses_to_test}

## Files to Start With

These are suspected files — start here, expand if needed:
{file_list_with_brief_descriptions}

## What to Deliver

1. Identify the root cause
2. Implement a fix
3. Add a comment at the fix site explaining the root cause
4. Run tests to verify: {test_commands}
```

## Notes on Prompt Construction

- **Always list file paths explicitly** — Codex should not need to `find` or `grep` across the repo
- **Include previous attempts** — prevents Codex from repeating failed approaches
- **State constraints clearly** — what NOT to change is as important as what to change
- **Include test commands** — so Codex can self-verify before finishing
- **If codex-feedback-planning was used**, paste its findings into the prompt under a "Known Risks" section
