# ship — aligned idea → review-ready PR, quality-gated end to end

The headline skill. `/ship` takes a task that's already aligned and drives it all the way to
a review-ready pull request with as few interruptions as possible, while guaranteeing that
what lands is the **highest-quality version** I can produce, not just the first version that
runs.

## What it does

Once a design is settled (I run `/align` first), `/ship` runs the build loop on its own and
stops for me only where a human actually has to decide. The beats:

1. **Scope** — restate the goal in two lines; bail back to `/align` if it's fuzzy or spans
   several features.
2. **Spec** — written into my `.doruk/` memory layer, kept out of the PR diff.
3. **Cross-model spec review** — a *different* model reads the spec against the real repo and
   critiques it. I fold in what's right.
4. **Plan** — the implementation plan, into the same folder.
5. **Cross-model plan review** — a fresh pass on the plan, because spec-level and plan-level
   blind spots aren't the same.
6. **Simplification pass** — a complexity/over-engineering review of the plan, with an
   explicit do-not-cut list so it can't delete correctness, security, or schema work.
7. **Execute** — subagents for independent parallel work, inline for coupled/sequential work.
8. **PR** — opened with the project's normal PR ritual.
9. **Review gate** — the one guaranteed stop. An automated reviewer runs, I get every finding
   by severity in plain language, and I drive the fixes until I say the PR is solid. The skill
   never merges; I own the merge.

Two early-exits keep it honest: a **blocking** design flaw from a cross-model review stops the
loop, and it will **never fake green** — if tests fail or it's stuck, it says so.

## Why I built it

I kept getting one of two bad outcomes from "just build it" sessions. Either the agent
check-in-spammed me at every micro-step, or it ran off and produced a large diff I then had to
reverse-engineer and quality-check by hand. I wanted the middle path: run autonomously, but
gate on the decisions that matter, and bake the quality review *into* the loop instead of
bolting it on at the end.

The non-obvious part is **who reviews**. A single model that writes a plan and then reviews its
own plan just agrees with itself, so the blind spots survive into the code. So `/ship` routes
the spec and the plan through a *genuinely different model* (twice, because the spec and the
plan fail in different ways), and then runs a dedicated simplification pass before any code is
written. By the time I'm executing, three independent viewpoints — quality, complexity, and
simplification — have already shaped the plan. The result is that the version that ships is the
reviewed one, by construction, not by my remembering to ask for a review afterward.

## What's mine, and what I'm composing

I want to be precise about this, because `/ship` is mostly an **orchestrator** and a lot of the
muscle underneath it is other people's work.

**Mine:** the orchestration itself — the order of the beats, the human-in-the-loop gates, the
"always review quality before it ships" discipline, the rule that the spec lives in `.doruk/`
and never enters the PR diff, the work-type judgment for when to run vs skip the simplification
pass, and the do-not-cut safety list that makes that pass safe. That design, and the way these
pieces are wired into one gated pipeline, is what I actually built.

**Not mine — composed and credited:**

| Beat | Driven through | Built by | Honest description |
|---|---|---|---|
| Brainstorm / plan-writing / execution | the **superpowers** skill collection | a third party (not me) | I sequence and gate these skills; I did not write them. |
| Simplification / over-engineering review | the **ponytail** skill | a third party (not me) | I decide when to run it and feed it a do-not-cut list; the simplifier itself isn't mine. |
| Cross-model spec & plan review | my own `codex-feedback-planning` skill | orchestration mine; **Codex CLI/model OpenAI's** | My skill drives the OpenAI Codex CLI read-only. I did not build Codex or the model behind it. |

If a composed skill isn't installed in your environment, `/ship` says so and falls back to the
plain built-in equivalent (write the spec/plan directly, review it manually) rather than
pretending a gate ran. See [`PROVENANCE.md`](../../../PROVENANCE.md) for the full accounting.

## How to use it

1. Settle the design first with `/align`. `/ship` is for *aligned* ideas; it will kick fuzzy or
   multi-feature scope back to alignment.
2. Drop this `ship/` folder into `~/.claude/skills/` (or a project's `.claude/skills/`).
3. For the full quality gates, also install the composed pieces: the superpowers collection,
   the ponytail skill, and my `codex-feedback-planning` skill (which needs the OpenAI Codex CLI:
   `npm i -g @openai/codex && codex auth`). Without them, `/ship` still runs — it just reviews
   manually where a gate would have run.
4. Say **`/ship <topic>`**, **"run the loop"**, or **"take this to a PR"**. Force the execution
   mode with `--inline` or `--subagent`; open a draft PR with `--draft`.

`/ship` then runs the loop, reporting progress in batches, and stops at the review gate for me
to drive the fixes. It pairs with `/discuss` (loose exploration) and `/align` (one-question
convergence) — those settle *what* to build; `/ship` builds it well.
