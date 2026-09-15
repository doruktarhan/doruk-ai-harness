# Codex Consultant Mode

Codex reads the real codebase and critiques a plan, spec, or diff. `--sandbox read-only`
enforces that at the CLI level, so the contract does not rest on the prompt.

## 1. Gather context

- **Task** — what the user wants, stated objectively (what must happen, not why this approach was picked).
- **The artifact** — the full plan, spec, or diff under review.
- **File paths** — exhaustive, so Codex reads instead of exploring: files to be changed, the
  interfaces/types/contracts they depend on, related tests, affected config.

## 2. Build the prompt

```
You are an external code consultant. Read and analyze only — do not create, edit, or delete
files, and do not run state-changing commands. Produce written analysis.

## Task
{task_description}

## Artifact Under Review
{plan_or_spec_or_diff}

## Files to Read
{file_list}

## Your Analysis
1. Problems & risks — race conditions, data loss, breaking changes, missing edge cases,
   dependency conflicts, performance regressions, security concerns.
2. Design critique — better patterns, simpler approaches, over- or under-engineering.
3. Missing considerations — error handling, rollback, migration path, backward
   compatibility, testing gaps.
4. Sequencing — is the order right, do intermediate states break the system, any circular
   dependencies?
5. Agreements — what is solid.

Be specific: cite file paths, function names, line numbers. No generic advice.
```

Swap sections 1–5 for a focused set when the artifact calls for it:

- **Architecture** (new service, schema change, API redesign): coupling and cohesion,
  scalability, migration safety (incremental vs big-bang), API contract stability, data flow
  through layers.
- **Refactor** (structure changes, behavior fixed): behavioral preservation, per-step
  verifiability and checkpoints, import/require chains at intermediate steps, whether
  existing tests catch regressions, a less disruptive alternative.

## 3. Choose the model

Review runs on Sol by default and escalates to Astra. Neither ever runs labor — that is
Luna's job, see [implementer.md](implementer.md).

| Model | Use for |
|-------|---------|
| `gpt-5.6-sol` | Ordinary code review, routine diff gates, small or constrained changes. |
| `gpt-6-astra` | Big architectural changes (new subsystem, cross-cutting refactor, a frozen API contract), backend builds (services, data layers, migrations, auth, concurrency, money or persistence in the blast radius), complex open-classification specs. |

The pin is mandatory: `~/.codex/config.toml` defaults to Luna, so an unpinned review silently
runs on the labor model.

Effort is the second dial, not a substitute for the model. Both tiers default to
`model_reasoning_effort="medium"`; go `high` only for very complex or open-ended artifacts.
Astra on a routine diff is money burned. Astra needs codex-cli 0.153.4+ — older versions
reject it with "requires a newer version of Codex".

## 4. Invoke

```bash
cd <project-root>
codex exec -m gpt-5.6-sol -c model_reasoning_effort="medium" --sandbox read-only "<prompt>" < /dev/null
```

`< /dev/null` closes stdin. Per `codex exec --help`, a piped stdin plus a prompt argument makes
Codex append stdin as a `<stdin>` block, so without the redirect it waits at "Reading
additional input from stdin..." for an EOF that never comes. A trivial probe can still finish
because the harness closes stdin on exit; real work hangs at 0% CPU.

Long prompts go through a temp file, passed as an argument (not piped):

```bash
cat > /tmp/codex_prompt.txt <<'PROMPT_EOF'
<prompt>
PROMPT_EOF
codex exec -m gpt-5.6-sol -c model_reasoning_effort="medium" --sandbox read-only "$(cat /tmp/codex_prompt.txt)" < /dev/null
```

Long reviews run in the background with polling:

```bash
( codex exec -m gpt-5.6-sol -c model_reasoning_effort="medium" --sandbox read-only "$(cat /tmp/codex_prompt.txt)" \
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

The redirect attaches to the inner `codex exec`, not the subshell — codex inherits stdin from
its parent.

Use `--sandbox workspace-write` only when a review genuinely needs to run a build.

## 5. Report

```
## Codex Review Summary

### Problems Identified
- [items]

### Alternative Approaches Suggested
- [items]

### Agreements with Current Plan
- [items]

### Recommendation
[Keep the plan, adopt Codex's suggestions, or hybrid]
```

Compare the findings against the original plan, then ask the user how to proceed. If a
delegation follows, carry these findings into the implementer prompt under "Known Risks".

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `codex: command not found` | `npm i -g @openai/codex && codex auth` |
| Hangs at "Reading additional input from stdin...", 0% CPU | stdin not closed — add `< /dev/null` to the codex invocation. Most common failure in non-interactive shells. |
| "requires a newer version of Codex" | Astra needs codex-cli 0.153.4+; upgrade or fall back to Sol. |
| `--full-auto` deprecation warning | Use `--sandbox workspace-write`; same behavior. |
| Prompt too long | Temp file plus `"$(cat …)"` — codex needs the prompt as an argument, not on a pipe. |
| Review times out | Split into focused questions, e.g. "review only the migration". |
| Codex edited files | `--sandbox read-only` was missing from the command line. The sandbox enforces read-only, the prompt does not. |
