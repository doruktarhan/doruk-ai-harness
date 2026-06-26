# System & Flow — how a unit of work moves through the harness

The heart of the harness is a **workflow**: a from-scratch, human-gated pipeline that takes
a task from a vague idea to a review-ready change, with code quality, complexity, and
simplification reviewed by **multiple models from different viewpoints** so that what ships
is always the highest-quality version, not the first one that compiles. Three beats:

```
   DISCUSS  ─▶  ALIGN  ─▶  SHIP
   (diverge)   (converge)  (build → multi-model review → review-ready PR)
        │           │              │
        └───────────┴──────────────┘
         human in the loop at every decision
```

Everything else in the harness exists to serve that workflow: a **state & memory** layer
(`.doruk/`) so each run orients on solid ground and compounds what it learns, and a
**delegation & isolation** layer so any beat can be handed to a different model in a
sandboxed git worktree without giving up control. This document covers all three, workflow
first.

---

## The workflow — discuss → align → ship

This is the headline of the harness. A task starts as a loose idea and ends as a
review-ready pull request, and a human is in the loop at **every** decision point. The
discipline that makes it worth running: at multiple points a *different* model reviews the
work for correctness, complexity, and simplification before it can move forward, so the
version that ships is the highest-quality one rather than the first that ran green.

The three beats are deliberately separated so each does one job well.

### 1. discuss — diverge before committing to a design

The first beat is **loose, divergent, thinking-out-loud** exploration — the opposite of
interrogation. Here the agent acts like a sharp colleague: it brings opinions, proposes
ideas, names tradeoffs, pokes at assumptions, and pushes back when it thinks the user is
wrong, all in short turns rather than one big funnel. The goal is to find the *shape* of the
thing.

What discuss deliberately does **not** do: converge, write a spec or plan, or write code. It
orients briefly on any existing state/handoff context (active or paused threads, a relevant
feature's orientation block) if a `.doruk/` layer exists, then just discusses. It holds the
gate — if the user starts drifting toward "just build it," it reminds them this is still
discussion and offers to move on. It hands off to `align` **only when the user explicitly
says so**, writing a tight summary of the decided shape and open questions so the user does
not have to repeat themselves.

### 2. align — converge on a shared design, one question at a time

The middle beat turns the idea into a design both sides agree on by **interviewing the user
one question at a time**, each question carrying the agent's recommended answer. If the
codebase can answer a question, the agent goes and looks instead of asking. It does not move
on while an answer is still vague — it pins each point down first.

Depth scales to the work:

- **Soft** — a few questions on the genuinely open points, then converge. For small or
  already-clear work.
- **Hard** — relentless: walk every branch of the decision tree, resolve dependencies one
  by one, let no vague answer slide. For big, ambiguous, or architectural work.

When unsure, it starts soft and goes deeper only where answers stay fuzzy. When aligned, it
summarizes the agreed design and offers to run `ship`. Align runs **before** ship by design:
ship will kick a still-fuzzy or multi-feature scope back here rather than build on sand.

### 3. ship — drive the aligned spec to a review-ready PR

The build beat runs the whole loop with **minimal check-ins**, stopping for a human only at
the decision points that actually need a person. The single *planned* stop is the review
gate at the end; every other stop is conditional. The loop's whole reason for existing is
that what ships is the highest-quality version, so a *different* model reviews the work for
correctness, complexity, and simplification at several points before it can move forward.

Ship **composes** existing pieces rather than reimplementing them — the orchestration (the
order, the human gates, the always-review-quality discipline) is the contribution. The flow:

1. **Scope** — state goal + scope in ~2 lines. If it spans multiple independent features or
   is still fuzzy, stop and send the user back to `align`.
2. **Spec** — write the spec into the memory layer (`.doruk/features/<topic>/`). This folder
   is working state, not deliverable; it stays out of the PR diff.
3. **Cross-model spec review** — a *different* model critiques the spec against the real
   repo. Fold in the feedback. (No external CLI? Say so and review it yourself.)
4. **Plan** — write the implementation plan into the same folder.
5. **Cross-model plan review** — a *fresh* pass on the plan (not the spec). Spec-level and
   plan-level blind spots differ, so both get an independent viewpoint.
6. **Simplification pass** — a deletion-biased complexity reviewer (the third-party **ponytail** skill) runs on the plan **when**
   the work adds new code with defensive or speculative surface (new reports, tool
   libraries, services, components), and is **skipped** (with a one-line reason) on small
   already-reviewed diffs or on contracts / migrations / prompts / persona where such a
   reviewer misfires. It runs with the locked design plus an explicit **do-not-cut list**
   (correctness fixes, escaping, input validation, security, schema/contract bumps) so it
   cuts safely. Accepted cuts fold back into the plan.
7. **Execute** — pick the execution mode by task shape and say which and why in one line:
   independent / parallelizable / large surface → one subagent per independent task;
   coupled / sequential / small / heavy shared context → inline in this session.
8. **PR** — open the pull request with the project's normal ritual. Never push from a
   worktree or open a PR on uncommitted work.
9. **Review gate — stop for the human.** Trigger whatever automated PR reviewer the project
   uses (a CI review bot, a hosted review service, or a second-model review on the diff) and
   wait. Present **every** finding by severity in plain language, each with a recommended
   action. Fix the clear ones, surface the judgment calls for the human, iterate until the
   human says the PR is solid. **Do not merge** — review-ready is the finish line; the human
   owns the merge.

Ship stops early only when a cross-model review flags a **blocking** design flaw, when tests
genuinely won't pass (never fake green), or when scope turns out to be unsettled or
multi-feature (kick back to `align`). Between steps it reports progress in **batches**, not
step by step — minimal check-ins were the ask.

> **The quality engine.** Steps 3, 5, and 9 are the centerpiece: spec review, plan
> simplification, and the final diff review are each an *independent* viewpoint, and they
> can come from different models. The point is not redundancy for its own sake — spec-level,
> plan-level, and diff-level blind spots are genuinely different, and a model that did not
> write the work catches what the author cannot see. The composed pieces are third-party and
> not the author's work — the **superpowers** build-loop scaffold and **ponytail** simplification,
> credited in the repo's README and PROVENANCE; the orchestration is.

---

## State & memory — the `.doruk/` layer

The workflow needs somewhere to remember what it is doing across stateless sessions,
machines, and parallel agents. That is the `.doruk/` layer: a portable state folder any
agent reads to orient itself before touching code, and writes back to so each unit of work
starts from a richer base than the last.

The point: an LLM coding session is stateless. Without a durable, agent-readable record of
*where the work stands* and *what the next move is*, every new session re-derives context
from scratch and drifts. `.doruk/` is that record — small enough to read first, structured
enough to trust. Because it is committed (in solo repos) or kept as a private workspace (in
team repos), orientation works identically on any machine and across several agents at once.

Two horizons:

- **Short-term (working memory)** — `STATE.md` plus each feature's `handoff.md`. Optimized
  for fast orientation and tight coordination, built around the *"what's the next move?"*
  test so it stays a board, not a log. Trimmed every session; detail flows down into the
  durable record rather than accumulating here.
- **Long-term (durable memory)** — `feature.md` records plus `MEMORY.md` / `memory/` notes.
  Optimized for *future* readers: decisions and their WHY, gotchas, cross-feature learnings.
  This is what makes work **compound** — each unit of work writes back what it learned.

Three verbs maintain this layer:

- **handoff** — the universal state organizer. It keeps `STATE.md` (the landscape) and each
  feature's `handoff.md` (live coordination) current, bootstraps `.doruk/` on first use, and
  has explicit paths for continuing, picking up, finishing, or abandoning a feature.
- **feature-organize** — the on-ship distiller. When a feature closes (or a sub-deliverable
  ships mid-feature), it rewrites `feature.md` into a durable record and triages the
  in-flight scratch (keep / archive / delete), so a future agent finds knowledge, not the
  mess of mid-flight notes.
- **wrap** — the end-of-session checklist for a multi-agent setup where several agents share
  one feature but each owns a single folder. It runs consistency checks (state agreement
  between a folder's README and the shared STATE, stale-link scan, cross-folder write
  detection, handoff trim, decision-date convention) and then makes the mechanical
  end-of-session updates. It composes with handoff: run wrap first, then handoff.

The discipline that holds it together: **reference, don't duplicate.** Each fact has one
home. The board points at the record; the record points at the PR. Nothing is snapshotted in
two places to drift apart. Writes are **Markov** — current state only, never appended
history (git history is the audit log).

### The `.doruk/` folder convention

All harness state lives in one folder at the repo root. The single-owner-per-feature layout:

```
.doruk/
├── STATE.md                     # the landscape: thin index + backlog of future work
├── MEMORY.md                    # durable, cross-feature learnings (the index)
├── memory/                      # longer memory notes, one file per topic
│   ├── <topic-a>.md
│   └── <topic-b>.md
└── features/
    └── NN-slug/                 # one folder per feature, numbered + slugged, permanent
        ├── feature.md           # the durable record: orientation, decisions + WHY, gotchas
        ├── handoff.md           # this feature's live, in-flight handoff
        ├── task-NN-slug/        # optional: a delegated task's spec (multi-task features)
        └── archive/             # scratch that was only true during the work (optional)
```

Three tiers, no overlap: **STATE.md** (read first) is a thin index plus backlog;
**handoff.md** is one feature's live coordination; **feature.md** is the durable record,
written on ship by a distillation step rather than by routine handoffs.

#### `STATE.md` — the landscape

The cross-feature board answers "what is the world right now" in zones:

- **Active** — work in motion where the agent can name the **next move**. That single
  question is the organizing test: name a next action → active; can't, and it's shipped or
  abandoned → not active. *In-hand* work touched this session gets a full block; *warm*
  threads to return to get a 2–3 line short notice.
- **Recent / paused** — one-liner per *cold* thread: dormant work with no current next move.
  Its purpose is disambiguation when "continue with the X work" could mean several threads.
  It is **not** a completed-work archive — `ls features/` is the index.
- **Cleanup / backlog** — orphan infrastructure that belongs to no single feature (worktrees
  still on disk after a merge, stacks to tear down, temp files), and future work that has no
  folder yet (promoted to a feature when picked up).

Conventions that keep it honest: **reference, don't duplicate** (presence and intent only);
**link work, don't snapshot its status** (write the PR reference, not "merged" as prose —
read live status from the host); **soft caps** (a few lines per active entry — overflow is
the signal to push detail down into `feature.md`); and in a parallel-agent setup, each agent
edits only its **own fenced section** and re-reads the file immediately before editing.

#### `features/NN-slug/` — one folder per feature

A numbered, slugged folder, permanent (update, never delete). While work is in flight agents
dump freely into it; on ship it gets distilled. Two canonical files:

**`feature.md` — the durable record.** Rewritten on ship. It opens with an **orientation
block** so a picking-up agent loads context in seconds:

```
> Status: <in progress | shipped — PR #NNNN merged YYYY-MM-DD | research only | abandoned — why + replacement>
> Next:   <the single next move>   (dropped once shipped)
> Key files: <2–4 paths a future agent opens first>
```

Below it: **what it does** (2–3 sentences), **what changed** (PRs / commits / files),
**decisions + WHY** (macro choices only — the WHY survives), **gotchas**, and **follow-ups**.
A navigator table is added only if auxiliary files survive triage.

**`handoff.md` — the feature's live handoff.** Current branch and status, what the work is
about, what's being done right now, a task board for multi-task features, and "don't touch"
coordination hints. Short-lived, trimmed to a cap each session, with detail pushed into
`feature.md` as it grows. The split is deliberate: `feature.md` is the **durable**
description, `handoff.md` is the **current state**.

#### `MEMORY.md` + `memory/` — durable, cross-feature learnings

The index of learnings that outlive any one feature: debugging insights, anti-patterns,
architecture facts, recurring conventions. When an entry grows past a line or two it moves to
its own file under `memory/` and `MEMORY.md` keeps a pointer. This is the long-term
substrate; `STATE.md` and the per-feature `handoff.md` files are the short-term working
memory.

---

## Delegation & isolation — hand a beat to a different model

Any beat of the workflow can be handed to a **different model** — OpenAI Codex or Google
Gemini — without giving up control or safety. The isolation primitive is the git worktree:
the delegate works in its own sandboxed checkout, and the driving agent reviews the diff
before any of it reaches the main branch. This is the same isolation that lets several units
of work run in parallel without colliding.

### The worktree — the isolation primitive

A git worktree is an isolated checkout of one branch in its own directory, separate from the
main checkout. Several worktrees of the same repo can exist at once, each on a different
branch, so multiple agents (or delegated models) build and test in parallel while the main
checkout stays clean.

Two skills cover the worktree lifecycle:

- **worktree-init** — creates the worktree, then does the part `git worktree add` alone
  misses: copies the untracked local files that never travel with git (`.env`, agent /
  editor config, IDE rules) and bootstraps the environment (install deps), so the new tree
  actually runs instead of erroring on a missing secret or empty environment. Large build
  artifacts are rebuilt, not copied. Worktrees live in a sibling directory outside the repo
  to avoid nesting one git tree inside another.
- **worktree-lifecycle** — the operating manual for an agent *inside* a worktree. It reads
  the spawn-written context file to learn its branch, its own path, and the main checkout's
  path, then follows the build / test / cleanup rules.

Isolation rules for any agent inside a worktree:

- **Each worktree gets its own slice of shared host resources** — its own ports, its own
  container-stack project name — so siblings don't collide. Check what's already listening
  before starting anything long-running.
- **Commit early and often.** A worktree can be removed at any time; uncommitted work is gone.
- **Never push from a worktree without an explicit ask**, and don't edit shared/global config
  from inside one (those are copies — change them in the main checkout).
- **Stay in your lane.** Do task work on this branch in this directory; don't reach into a
  sibling worktree or check out a different branch here.

### Two roles a delegate can play

| Role | What it does | Write access |
|---|---|---|
| **Consultant** (read-only) | Critiques a plan, an architecture, or existing code. Returns problems, alternatives, and agreements — makes **no** changes. | none |
| **Implementer** | Does the implementation in an isolated worktree. The driving agent reviews and merges or discards. | sandboxed to its worktree |

When to reach for each:

- **Consultant** — after a non-trivial plan is created (multiple files or an architectural
  change), to catch design issues *before* coding. Also any time a second opinion from a
  different model is wanted on a plan, design, or diff. This is the role the ship beat's
  cross-model spec and plan reviews use.
- **Implementer** — when the driving agent is stuck after a couple of honest attempts, when
  a task needs more codebase context than fits comfortably in one window, or when the user
  explicitly asks. Not for first attempts or trivial fixes — try it yourself first.

### The delegation loop (implementer role)

1. **Isolate** — create a worktree on a descriptive branch so the delegate's changes are
   sandboxed.
2. **Brief** — gather an exhaustive context pack: the task, what was already tried and why it
   failed (so the delegate doesn't repeat it), every relevant file path, and concrete success
   criteria (test commands, expected behavior). Include any prior consultant findings.
3. **Invoke** the model's CLI in its worktree with full write access for the run.
4. **Review** the resulting diff: does it solve the actual problem, does it touch only what
   it should, any anti-patterns or security issues?
5. **Test** inside the worktree. On pass, merge and remove the worktree. On failure, re-brief
   the delegate with the failure output, fix minor issues by hand, or discard the worktree
   entirely (zero risk to main).

### Two invariants when driving an external CLI non-interactively

- **Sandbox the writes.** Run the implementer in workspace-write / yolo mode *inside the
  worktree* so it works without per-action prompts, while the worktree boundary contains the
  blast radius. Read-only consultant runs use the CLI's plan/approval mode, which enforces
  no-writes at the CLI level — a prompt instruction alone is not enough.
- **Close stdin.** When invoking a delegate CLI from a non-interactive shell, redirect stdin
  from `/dev/null` on the CLI invocation itself. Without it the CLI can hang at 0% CPU
  waiting for end-of-input. This is the single most common failure mode in scripted
  delegation. (For background runs the redirect attaches to the inner CLI command, not the
  subshell — the CLI inherits stdin from its parent.)

Three delegation skills implement this shape:

- **codex-feedback-planning** — Codex as a read-only consultant on a plan or design.
- **codex-task-delegator** — Codex as an implementer in an isolated worktree.
- **gemini-delegate** — Gemini in *either* role (consultant via plan mode, implementer via
  yolo + worktree), auto-selecting the mode from the task.

Why two providers and two roles share one shape: the harness can get a second opinion from a
*different* model (one provider already weighed in), compare approaches across providers
before committing, or route a task to whichever model's strengths fit it — all through the
same isolate → brief → review → merge loop, so switching models costs nothing in process.

---

## How it all composes

The **workflow** is the spine: discuss finds the shape, align converges on a design,
ship drives it to a review-ready PR with quality reviewed by multiple models at every gate.
The **state & memory** layer is what the workflow orients on before it starts and writes back
to after it finishes, so each run compounds. **Delegation & isolation** is how any beat —
a spec review, a plan critique, a stuck implementation — gets handed to a different model
safely, in a worktree, with the driving agent reviewing the diff before anything reaches
main. One workflow, one folder of state, many models.
