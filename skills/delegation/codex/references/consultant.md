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
| `gpt-6-sol` | Ordinary code review, routine diff gates, small or constrained changes. |
| `gpt-6-astra` | Big architectural changes (new subsystem, cross-cutting refactor, a frozen API contract), backend builds (services, data layers, migrations, auth, concurrency, money or persistence in the blast radius), complex open-classification specs. |

The pin is mandatory: `~/.codex/config.toml` defaults to Luna, so an unpinned review silently
runs on the labor model.

Effort is the second dial, not a substitute for the model. Both tiers default to
`model_reasoning_effort="medium"`; go `high` only for very complex or open-ended artifacts.
Astra on a routine diff is money burned. Astra needs codex-cli 0.153.4+ — older versions
reject it with "requires a newer version of Codex".

## 4. Invoke

Write the prompt to a file, then run the wrapper as a background Bash; its exit wakes you:

```bash
cat > /tmp/codex_prompt.txt <<'PROMPT_EOF'
<prompt>
PROMPT_EOF
~/.claude/skills/codex/scripts/codex-run.sh gpt-6-sol medium read-only <project-root> \
  /tmp/codex_prompt.txt /tmp/codex_review.txt 1500
```

Read `/tmp/codex_review.txt`: the answer, then a last line `CODEX_EXIT=<rc>` or
`CODEX_KILLED=<reason>`. The header, session id and tool calls are in
`/tmp/codex_review.txt.log`. On `CODEX_KILLED`, rerun once; if it is killed again, fall back
to `gpt-6-sol` or split the review.

The wrapper closes stdin (`< /dev/null`): a piped stdin plus a prompt argument makes Codex
append stdin as a `<stdin>` block and wait for an EOF that never comes. It also caps wall
time at MAX_S (default 1500 s), kills a run with no `session id:` line after 120 s, and
kills one silent for 600 s. A plain `timeout 900 codex exec …` fails on macOS (no `timeout`
binary), and the Bash tool's `timeout` is ignored under `run_in_background`.

Use `workspace-write` as the SANDBOX argument only when a review genuinely needs to run a build.

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
| `CODEX_KILLED=no session id after 120s` | Codex never started a session (stdin open, or a local startup block). `Reading additional input from stdin...` prints on every run; the missing `session id:` line is the signature. Rerun through the wrapper once. |
| `timeout: command not found` | macOS ships no `timeout`; the wrapper is the cap. |
| A background run outlives the Bash `timeout` | That parameter is ignored with `run_in_background`; the wrapper's MAX_S is the cap. |
| "requires a newer version of Codex" | Astra needs codex-cli 0.153.4+; upgrade or fall back to Sol. |
| `--full-auto` deprecation warning | Use `--sandbox workspace-write`; same behavior. |
| Prompt too long | The wrapper passes the prompt file as one argument (codex needs it as an argument, not on a pipe); macOS caps arguments near 1 MB, so point Codex at files to read instead of pasting them. |
| Two runs clobber each other | Use one prompt and one OUT path per run (your scratchpad or `mktemp`), not the fixed `/tmp` names in the examples. |
| `CODEX_KILLED=over 1500s wall clock` | Split into focused questions, e.g. "review only the migration", or raise MAX_S. |
| Codex edited files | `--sandbox read-only` was missing from the command line. The sandbox enforces read-only, the prompt does not. |
