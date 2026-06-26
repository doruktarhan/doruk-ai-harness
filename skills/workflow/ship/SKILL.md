---
name: ship
description: "Use when an idea is already aligned and you want it driven from spec to a review-ready PR with minimal check-ins and built-in multi-model quality gates. Run /align first if the scope isn't settled. Triggers on /ship, 'run the loop', 'take this to a PR', 'ship it'."
argument-hint: "<topic> [--inline | --subagent] [--draft]"
user_invocable: true
metadata:
  author: doruktarhan
  version: "1.0.0"
  domain: workflow
  role: orchestrator
---

# /ship — Aligned idea → review-ready PR

Drive the whole build loop with minimal check-ins, stopping for a human only at the
decision points that actually need a person. The **single planned stop** is the review
gate (step 9); every other stop is conditional and named below. The loop's whole reason
for existing is that what ships is the **highest-quality version**, not the first one that
compiles: at multiple points a *different* model reviews the work for correctness,
complexity, and simplification before it can move forward.

If the scope isn't settled yet, stop and tell the user to run `/align` first.

> This skill **composes external pieces** rather than reimplementing them. The
> brainstorming / plan-writing / execution beats are driven through the third-party
> **superpowers** skill collection; the simplification pass is driven through the
> third-party **ponytail** skill; cross-model plan review is driven through the
> author's own `codex-feedback-planning` skill (which itself orchestrates the OpenAI
> Codex CLI). The *orchestration* — the order, the human gates, the always-review-quality
> discipline — is the contribution here. The composed tools are credited in the README and
> PROVENANCE and are **not** the author's work. If a composed skill isn't installed, say so
> and fall back to the plain built-in equivalent (write the spec/plan directly, review
> manually) rather than pretending the gate ran.

## Flow

1. **Scope** — state the goal + scope in ~2 lines. If it spans multiple independent
   features, or is still fuzzy, **stop** and suggest `/align`.
2. **Spec** — write the spec into the memory layer, `.doruk/features/<topic>/`. This folder
   is working state, not deliverable: keep it out of the PR diff (it's gitignored in team
   repos; in a solo repo it's committed but lives outside the code the PR touches).
3. **Cross-model spec review** — run `codex-feedback-planning` on the spec so a *different*
   model critiques it against the real repo. Fold in the feedback. (No Codex CLI? Say so and
   review the spec yourself before continuing.)
4. **Plan** — write the implementation plan into the same folder. Use the superpowers
   plan-writing skill if present; otherwise write a plain step-by-step plan.
5. **Cross-model plan review** — a *fresh* `codex-feedback-planning` pass on the plan (not
   the spec). Fold in the feedback. This is the second independent viewpoint: spec-level and
   plan-level blind spots are different, so review both.
6. **Simplification pass (ponytail)** — decide whether the plan deserves a complexity/
   simplification review, then run the ponytail skill on it. Judge by work-type:
   - **Run it** when the work adds new code with defensive or speculative surface (new
     reports, tool libraries, services, components) — that's where over-engineering hides.
   - **Skip it** (with a one-line reason) when it's a small, already-reviewed diff, or when
     it touches contracts / migrations / prompts / persona, where a deletion-biased reviewer
     misfires.
   Run inline by default: the simplifier needs the locked design **plus an explicit
   do-not-cut list** (correctness fixes, escaping, input validation, security, schema/
   contract bumps) so it cuts safely. Spawn a subagent only for a large plan, and hand it
   that same context. Fold accepted cuts back into the plan, then continue.
7. **Execute** — pick the execution mode by task shape and say which + why in one line:
   - independent / parallelizable / large surface → subagent-driven execution (one
     subagent per independent task).
   - coupled / sequential / small / heavy shared context → inline execution in this session.
   - `--subagent` / `--inline` force the choice.
   Use the superpowers execution skills if present; otherwise execute the plan directly.
8. **PR** — open the pull request with the project's normal ritual (`gh pr create`, or a
   project-specific PR wrapper skill if one exists). `--draft` opens it as a draft. Never
   push from a worktree or open a PR without the work being committed.
9. **Review gate — stop for the human.** Trigger whatever automated PR reviewer the project
   uses (a CI review bot, a hosted code-review service, or a second-model review via
   `codex-feedback-planning` / `gemini-delegate` on the diff) and wait for it to report.
   Present **every** finding by severity, in plain language, each with a recommended action.
   Fix the clear ones, surface the judgment calls for the human to decide, and iterate until
   the human says the PR is solid. **Do not merge** — review-ready is the finish line; the
   human owns the merge.

## Stop early only when

- A cross-model review flags a **blocking** design flaw — surface it and stop; don't push on.
- Tests won't pass, or you're genuinely stuck — say so and stop. **Never fake green.**
- The scope turns out to be unsettled or multi-feature — kick back to `/align`.

## Reporting

Between steps, report progress in **batches**, not step by step. The human asked for minimal
check-ins; respect that. The only mandatory interactive stops are the review gate (step 9)
and the conditional early-stops above. Everything else runs without asking.
