# Gemini Implementer Prompt Templates

Templates for hands-on work in an isolated git worktree. Gemini runs with `--yolo` so it can edit, create, and delete files freely — be precise about scope.

## Template 1: Bug Fix (after Claude's failed attempts)

```
You are working in a git worktree with full write access. Implement a fix for the bug below.

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
- Keep changes minimal — fix the bug, do not refactor
```

## Template 2: Feature Implementation (context-heavy)

```
You are working in a git worktree with full write access. Implement this feature.

## Task

{feature_description}

## Architecture Context

{relevant_architecture_overview}

## Approach Guidance

{plan_or_approach_notes}

{if_consultant_review_was_used}
## Known Risks (from prior plan review)

A plan review identified these concerns:
{prior_review_findings}

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
You are working in a git worktree with full write access. Implement this refactor.

## Task

{refactor_description}

## Why This Refactor

{motivation — what's wrong with the current structure}

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

## Template 4: Research + Fix (root cause unknown)

```
You are working in a git worktree with full write access.

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

## Prompt Construction Notes

- **Always list file paths explicitly** — Gemini should not need to `find` or `grep` across the repo.
- **Include previous attempts** — prevents Gemini from repeating failed approaches.
- **State constraints clearly** — what NOT to change is as important as what to change.
- **Include test commands** — so Gemini can self-verify before finishing.
- **Paste prior consultant findings** when available — paste under "Known Risks" so Gemini avoids known pitfalls.
- **Reinforce scope** — without explicit boundaries `--yolo` mode will sometimes wander into adjacent files.
