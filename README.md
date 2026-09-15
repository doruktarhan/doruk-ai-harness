# doruk-ai-harness

**A coding harness for Claude Code, built as a system — not a pile of skills.**
Work starts in `discuss`: loose, opinionated exploration to find a task's shape, with an optional
structured-question round to pin down what's left. From there you build directly, or hand a
multi-step build to `orchestrate`, which delegates every unit of work to model-tiered subagents and
gates the design and the final diff with a genuinely different model, so what lands is always the
highest-quality version. Three supporting blocks back it: a committed `.doruk/` **state & memory**
layer, cross-model **delegation** in isolated git worktrees, and **understanding** skills that turn
an outcome into something a human can actually absorb.

[Workflow](#1-workflow--the-headline-skillsworkflow) · [State & Memory](#2-state--memory-skillsstate-memory) ·
[Delegation](#3-delegation-skillsdelegation) · [Understanding](#4-understanding-skillsunderstanding) ·
[Meta](#5-meta-skillsmeta) ·
[Install](#install) · [Demo](#see-it-in-motion--demo-app) · [Showcase page](web/index.html)

---

## Why I built this

> *First person, because it's mine and I want to be honest about why it exists, not sell it.*

Two things kept going wrong when I built with an AI agent. First, **"just build it" sessions went
sideways**: either the agent spammed me at every micro-step, or it ran off and produced a large diff
I then had to reverse-engineer and quality-check by hand. Second, **the context window is a terrible
memory**: it evaporates on compaction or a new session, it doesn't travel across machines, and it
rots silently as the model paraphrases its own earlier notes.

So I built a system instead of collecting prompts. The **workflow** is the spine: a task starts in
loose discussion, then either gets built directly or handed to `orchestrate` for a delegated,
model-tiered build, with a human in the loop at every real decision and, on a delegated build, the
quality, complexity, and simplification reviewed by a *genuinely different* model at each gate. The
point is structural: the version that lands is the reviewed one by construction, not because I
remembered to ask for a review afterward.

Underneath that, two supporting blocks do the unglamorous work. **State & memory** puts the memory on
disk: one committed `.doruk/` folder is the durable, indexed source of truth, and the context window
is treated as disposable scratch. **Delegation** lets me hand a unit of work to a *different* model
(OpenAI Codex, Google Gemini) inside an isolated git worktree, review its diff, and merge it or throw
it away with zero risk to the main branch.

### Why v3: trimmed for Fable-class models

OpenAI's September 2026 post *"Rethinking skills and prompts for GPT-6 Astra"* argues that
scaffolding built to babysit a weaker model — broad triggers, mandatory pre-reads, CAUTION/NEVER
language — slows a frontier model down: it competes for triggers, gets read unneeded, and makes an
aligned model stop to ask instead of just doing the work. v3 applies that here: `align` folded into
`discuss` as an optional round, the two Codex skills merged into `codex`, and `ship`'s scripted
pipeline — built for pre-Fable models, dependent on the now-disabled `superpowers` plugin — is
superseded by `orchestrate`. Rules live in [`skills/meta/lean-instructions`](skills/meta/lean-instructions);
superseded skills stay in [`skills/legacy/`](skills/legacy/README.md).

---

## The system at a glance

The harness leads with the **workflow** pipeline, backed by two supporting blocks that operate on one
committed `.doruk/` state folder. The diagram below is the canonical view (also in
[`docs/diagram.md`](docs/diagram.md)).

```mermaid
flowchart TB
    subgraph WF["WORKFLOW · find the shape first (skills/workflow/)"]
        D["<b>discuss</b><br/><i>loose, opinionated exploration,<br/>optional structured-question round</i>"]
    end

    BUILD["build directly, or hand off to ORCHESTRATE<br/>model-tiered build + design/diff review gated by a different model"]
    D ==>|"shape found"| BUILD

    subgraph SM["STATE &amp; MEMORY · the committed .doruk/ layer (skills/state-memory/)"]
        direction TB
        SM1["<b>handoff</b><br/><i>STATE.md board + per-feature handoff.md</i>"]
        SM2["<b>feature-organize</b><br/><i>distill feature.md when work ships</i>"]
        SM3["<b>wrap</b><br/><i>end-of-session consistency + updates</i>"]
        SM4["<b>feature-roadmap</b><br/><i>durable step-spine for multi-step programs</i>"]
    end

    subgraph DG["DELEGATION · isolation + cross-model help (skills/delegation/)"]
        direction TB
        DG1["<b>worktree-init</b><br/><i>create isolated worktree, copy local files</i>"]
        DG2["<b>worktree-lifecycle</b><br/><i>build / test / cleanup inside a worktree</i>"]
        DG3["<b>codex</b><br/><i>OpenAI Codex — consultant or implementer</i>"]
        DG4["<b>gemini-delegate</b><br/><i>Google Gemini — consultant or implementer</i>"]
        DG5["<b>orchestrate</b><br/><i>which model, when — for subagent spawns</i>"]
    end

    D -.->|orients on| SM1
    BUILD ==>|runs in| DG
    BUILD -.->|writes back to| SM

    classDef wf fill:#1d4ed8,stroke:#1e3a8a,color:#eff6ff;
    classDef hitl fill:#b45309,stroke:#92400e,color:#fffbeb;
    classDef sm fill:#0e7490,stroke:#155e75,color:#f0fdff;
    classDef dg fill:#7c3aed,stroke:#5b21b6,color:#faf5ff;
    class D wf;
    class BUILD hitl;
    class SM1,SM2,SM3,SM4 sm;
    class DG1,DG2,DG3,DG4,DG5 dg;
```

The skills live under five category directories — `skills/workflow/`, `skills/state-memory/`,
`skills/delegation/`, `skills/understanding/`, `skills/meta/` — that exist for browsing (plus
`skills/legacy/`, kept for reference and not installed — see [§ Why v3](#why-v3-trimmed-for-fable-class-models)).
Each leaf is a standard Claude Code skill (`skills/<block>/<name>/SKILL.md`). For the full description see
[`docs/system-and-flow.md`](docs/system-and-flow.md) (the architecture),
[`docs/memory-system.md`](docs/memory-system.md) (why the memory layer is shaped the way it is), and
[`docs/diagram.md`](docs/diagram.md) (the diagram in isolation). The same content is presented as an
interactive, click-to-drill page in [`web/index.html`](web/index.html).

---

## 1. Workflow — the headline (`skills/workflow/`)

One skill: find the shape of a task before building it, then decide what's next yourself.

| Skill | Beat | What it does |
|---|---|---|
| **`discuss`** | explore | Loose, opinionated exploration *before* committing to a design — the agent brings takes and tradeoffs, not a fixed interrogation, and deliberately holds off on specs, plans, or code. Once the shape has genuinely converged, it may offer a short structured-question round (Claude Code's `AskUserQuestion`, 2–4 questions in one batch, each with a recommended answer) to pin down what's left. |

Discuss doesn't hand off to a fixed next skill. For most work, just build directly from there; for a
multi-step build you want delegated across model-tiered subagents, go to
[`orchestrate`](#3-delegation-skillsdelegation). Quality on a delegated build isn't a separate
pipeline stage — it's built into `orchestrate`'s review gates: a *genuinely different* model (Codex
Sol or Astra) reviews the design and the final diff before anything lands, so a single model never
grades its own work.

---

## 2. State & Memory (`skills/state-memory/`)

The committed `.doruk/` layer: how the harness remembers across sessions, machines, and parallel
agents. The mental model in one line: **treat the context window as RAM and `.doruk/` as the disk**.
One discipline holds it together: **reference, don't duplicate** — each fact has one home, the board
points at the record, the record points at the PR.

| Skill | Role | What it does |
|---|---|---|
| **`handoff`** | orient | Universal `.doruk/` state for any repo. Maintains a `STATE.md` landscape (active / parked / done, plus a backlog) and each feature's live `handoff.md`. Bootstraps `.doruk/` on first use, so a repo needs no manual setup. |
| **`feature-roadmap`** | plan | Durable step-spine for multi-step programs. When a feature has ordered phases that span sessions (craft→test→refine, a migration, an audit sweep), adds a `roadmap.md` beside `handoff.md` so the map never gets clobbered by Markov rewrites. `handoff.md` shrinks to a two-line pin; `roadmap.md` holds the full step list, a mermaid flow, and a checkable "Done when" per step. |
| **`feature-organize`** | distill | Post-ship distillation. Turns a feature folder's in-flight scratch into a durable `feature.md` record (decisions + WHY) and triages aux files: keep / archive / delete. Full mode rewrites on close; narrow mode appends one note when a sub-deliverable ships. |
| **`wrap`** | multi-agent | End-of-session wrap-up for multi-agent feature folders where each agent owns one folder. Runs 5 consistency checks (state agreement, stale links, cross-folder writes, handoff trim, date convention) then the mechanical updates. Composes with `handoff`. |

The substrate all three operate on:

```
.doruk/
├── STATE.md                # the landscape: what's in motion, what's parked  (read first)
├── MEMORY.md               # durable, cross-feature learnings (the index)
├── memory/                 # one note per topic
└── features/
    └── NN-slug/            # one folder per feature
        ├── feature.md      # durable record: orientation block + decisions + WHY
        ├── handoff.md      # live, in-flight handoff
        ├── roadmap.md      # durable step-spine (multi-step programs only)
        ├── step-0N-*/      # one folder per step, with artifacts (multi-step only)
        └── archive/        # scratch that was only true during the work (optional)
```

Committed to git on purpose — so state travels across devices (`git pull` and the memory is here),
history is a deletion backstop (trim ruthlessly; every prior version survives), and the record is
auditable. In team repos the folder is gitignored as a private workspace instead.

### How the pieces navigate

The files aren't a flat folder — they're a graph. `STATE.md` is the index you read first; it points
at the active feature; the feature's live `handoff.md` and its durable `feature.md` reference each
other; learnings that outlive a feature graduate up into the `MEMORY.md` index and get recalled later.
The discipline is **reference, don't duplicate**: each fact has exactly one home, and everything else
links to it.

```mermaid
flowchart LR
    subgraph DK[".doruk/ — the memory harness"]
        direction LR
        STATE["<b>STATE.md</b><br/><i>the landscape / index<br/>active · parked · backlog</i>"]
        subgraph FEAT["features/NN-slug/"]
            direction TB
            HND["<b>handoff.md</b><br/><i>live, in-flight</i>"]
            REC["<b>feature.md</b><br/><i>durable record + WHY</i>"]
            SCR["<b>scratch / notes</b><br/><i>task-specific research</i>"]
        end
        IDX["<b>MEMORY.md</b><br/><i>cross-feature index</i>"]
        MEM["<b>memory/</b><br/><i>one note per topic</i>"]
    end

    STATE ==>|"opens the active feature"| HND
    STATE -.->|"a backlog item gets promoted"| FEAT
    HND <-->|"reference, don't duplicate"| REC
    HND -->|"working notes live beside it"| SCR
    REC ==>|"durable learning graduates up"| IDX
    IDX --> MEM
    MEM -.->|"recalled when relevant"| HND

    classDef idx fill:#0e7490,stroke:#155e75,color:#f0fdff;
    classDef rec fill:#155e75,stroke:#0c4a6e,color:#f0fdff;
    class STATE,IDX idx;
    class HND,REC,SCR,MEM rec;
```

**Who moves what** — the three state skills are the movers between these files:

| Navigation | Driven by |
|---|---|
| Read `STATE.md` → open the active feature's `handoff.md` → recall relevant `memory/` notes | **`handoff`** (+ recall) |
| Promote a backlog item in `STATE.md` into a new `features/NN-slug/` folder | **`handoff`** |
| When a feature becomes a multi-step program: add `roadmap.md` + `step-0N-*/` folders; shrink `handoff.md` to a pin | **`feature-roadmap`** |
| On ship: distill the live `handoff.md` into the durable `feature.md`, graduate learnings into `MEMORY.md` | **`feature-organize`** |
| End of session: check the files still agree, trim the board, fix stale links | **`wrap`** |

A new session never re-reads chat logs: it orients on `STATE.md`, walks into the one feature that's
moving, and the memory is already there.

---

## 3. Delegation (`skills/delegation/`)

Hand a unit of work to a **different model** — OpenAI Codex or Google Gemini — without giving up
control or safety, and isolate any branch work in its own git worktree. The git worktree is the
isolation primitive: the delegate works sandboxed in its own checkout, and the driving agent reviews
the diff before any of it reaches the main branch.

> **Honest scope.** The Codex and Gemini skills **orchestrate external CLIs I did not build** — I
> drive the OpenAI Codex CLI and the Google Gemini CLI as subprocesses. The skills are mine; the CLIs
> and the models behind them are not. See [`PROVENANCE.md`](PROVENANCE.md).

| Skill | Role | What it does |
|---|---|---|
| **`codex`** | both | Orchestrates the OpenAI Codex CLI as either a **read-only consultant** (plan/spec/diff review, pinned to **Sol**, reviews never run on the labor model) or a **worktree implementer** (pinned to **Luna at max effort**). One router skill picks the mode from the request. Merges what were two separate skills (`codex-feedback-planning`, `codex-task-delegator`), now kept in [`skills/legacy/`](skills/legacy/README.md) for reference. |
| **`gemini-delegate`** | both | Orchestrates the Google Gemini CLI in either role — read-only consultant or sandboxed worktree implementer. Same shape as `codex`, a different model. |
| **`orchestrate`** | reference | Which-agent-when lookup table for a build where every unit of work is delegated to a model-tiered subagent: Fable once up front for the hardest design/plan, Codex Luna at max effort for background labor and Sonnet for interactive labor, Opus for the tricky logic, Codex Sol for the review gates. Ships with an optional [`coordinator-hook.sh`](skills/delegation/orchestrate/coordinator-hook.sh) — a `SessionStart` hook that detects coordinator-tier models (Fable/Opus) and injects a pointer to this skill at session start; silent for everything else. Setup: [`HOOK-INSTALL.md`](skills/delegation/orchestrate/HOOK-INSTALL.md). |
| **`worktree-init`** | isolate | Creates an isolated git worktree for a branch, copies the untracked local files git won't carry (`.env`, IDE rules, agent config), and bootstraps the environment so the worktree runs immediately. |
| **`worktree-lifecycle`** | context | Auto-loaded operating manual for an agent running *inside* a worktree: orient, build/test with isolated host resources (own ports, own container-stack name), and clean up without losing uncommitted work. |

Two practical invariants the delegation skills encode, learned the hard way driving these CLIs
non-interactively: **sandbox the writes** (run the delegate in workspace-write / yolo mode inside the
worktree so the worktree boundary contains the blast radius) and **close stdin** (redirect
`< /dev/null` on the CLI invocation, or it hangs at 0% CPU waiting for end-of-input — the single most
common failure mode in scripted delegation).

---

## 4. Understanding (`skills/understanding/`)

Skills whose job is to make an *outcome* legible, not to produce one — turning a diff, a plan, or an
answer into something a human can actually absorb. In the same spirit as the built-in `simple` /
`tldr` re-explain knobs, but heavier-weight: instead of compressing text, this category renders a
standalone, explorable artifact.

> **Honest scope.** `explain-diff-html` is external — credit to Geoffrey Litt. See [`PROVENANCE.md`](PROVENANCE.md).

| Skill | Role | What it does |
|---|---|---|
| **`explain-diff-html`** | explain | Turns a code change, diff, branch, or PR into a self-contained HTML page: background, core intuition with toy examples, a walkthrough of the code, and a five-question interactive quiz to check understanding. |

---

## 5. Meta (`skills/meta/`)

Skills about how the other skills — and any instructions fed to a frontier model — get written.

| Skill | Role | What it does |
|---|---|---|
| **`lean-instructions`** | write/audit | Rules and an audit procedure for writing skills, `CLAUDE.md`/`AGENTS.md`, hooks, and task prompts for frontier models: narrow triggers, no unconditional pre-reads, permission statements instead of caution language, a stated Done condition. Derived from the OpenAI post cited above — see [`references/astra-2026-09.md`](skills/meta/lean-instructions/references/astra-2026-09.md). v3 (above) is this skill applied to itself. |

---

## See it in motion — demo app

[`demo-app/`](demo-app/) is a worked example: a **fictional, throwaway** todo-API project that exists
only to show a real, populated `.doruk/` mid-flight. Two features are live:

- **feature 01 · tag-filtering** — a plain-handoff feature (one `handoff.md` + `feature.md`). Read
  [`STATE.md`](demo-app/.doruk/STATE.md) first, then the live
  [`handoff.md`](demo-app/.doruk/features/01-tag-filtering/handoff.md) and the durable
  [`feature.md`](demo-app/.doruk/features/01-tag-filtering/feature.md).
- **feature 03 · csv-export** — a `/feature-roadmap` example: a 4-step program with a mermaid spine,
  step folders, and a pinned `handoff.md`. Read [`roadmap.md`](demo-app/.doruk/features/03-csv-export/roadmap.md)
  for the map, then [`handoff.md`](demo-app/.doruk/features/03-csv-export/handoff.md) for the pin.

A session ends; the next one rebuilds the full mental model in under a minute, with no archaeology
through chat logs.

---

## Install

Three ways to install, fastest first. All of them put every skill where Claude Code can discover it.

### Option 1 — install script (recommended, guaranteed)

`install.sh` copies **every leaf skill** (each `skills/<block>/<name>/`) into `~/.claude/skills/`,
**flattening** the category directories — the `workflow/`, `state-memory/`, `delegation/` folders
exist for browsing, but Claude Code discovers skills by name, so the installed layout is flat.
`skills/legacy/` is skipped on purpose — those skills are reference-only, never installed. It's
**idempotent** — safe to re-run; it overwrites the harness's own skills and never touches anything
else in that folder.

```bash
git clone https://github.com/doruktarhan/doruk-ai-harness.git
cd doruk-ai-harness
./install.sh           # copy all leaf skills into ~/.claude/skills/ (flattened)
./install.sh --dry-run # show what it would do, change nothing
./install.sh --help    # usage
```

Restart Claude Code (or start a new session) to pick up the newly installed skills.

### Option 2 — Claude Code plugin (via `/plugin`)

The harness also ships as a Claude Code **plugin**, served from its own single-plugin
**marketplace**. From inside Claude Code:

```
/plugin marketplace add doruktarhan/doruk-ai-harness
/plugin install doruk-ai-harness@doruk-ai-harness
```

- The first command registers this repo as a marketplace (it contains
  [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json)).
- The second installs the `doruk-ai-harness` plugin
  ([`.claude-plugin/plugin.json`](.claude-plugin/plugin.json)).

> **All 12 skills load natively.** The skills live under category subdirectories
> (`skills/<block>/<name>/`), and each leaf is declared explicitly in the plugin's
> [`skills[]` manifest](.claude-plugin/plugin.json). Claude Code reads that manifest, so the plugin
> route picks up every skill without flattening — no reliance on subdirectory recursion.
> `skills/legacy/` is deliberately absent from the manifest. `install.sh`
> (Option 1) remains an offline / non-Claude-Code fallback that flattens every leaf into
> `~/.claude/skills/` directly.

### Option 3 — manual copy

If you'd rather not run the script, copy the leaf skill folders yourself, flattening the category
dirs:

```bash
mkdir -p ~/.claude/skills
cp -R skills/*/*/ ~/.claude/skills/
```

Each `skills/<block>/<name>/SKILL.md` is a standard Claude Code skill with YAML frontmatter; dropping
the leaf folder into `~/.claude/skills/` is all that's required.

> **Configure once.** A few skills leave project-specific placeholders — base branch, test/lint
> commands, path conventions — marked inline as `<...>`. Fill them on first use, or wire them into a
> thin project wrapper skill that calls these.
>
> **External CLIs (delegation + orchestrate's review gates).** The Codex and Gemini skills require
> their CLIs to be installed separately and authenticated: `npm i -g @openai/codex && codex auth` ·
> `npm i -g @google/gemini-cli`. The skills check for these and tell you if they're missing.

---

## Repo layout

```
doruk-ai-harness/
├── README.md                     # you are here
├── install.sh                    # idempotent installer → flattens leaf skills into ~/.claude/skills/
├── LICENSE                       # MIT
├── PROVENANCE.md                 # honest attribution
├── .claude-plugin/
│   ├── plugin.json               # the doruk-ai-harness plugin (bundles all skills)
│   └── marketplace.json          # single-plugin marketplace for /plugin
├── skills/
│   ├── workflow/                 # discuss  (the headline)
│   ├── state-memory/             # handoff · feature-roadmap · feature-organize · wrap
│   ├── delegation/               # codex · gemini-delegate · orchestrate · worktree-init · worktree-lifecycle
│   ├── understanding/            # explain-diff-html (third-party, imported verbatim — see PROVENANCE.md)
│   ├── meta/                     # lean-instructions
│   └── legacy/                   # align · ship · codex-feedback-planning · codex-task-delegator — reference only, not installed
├── docs/                         # system-and-flow, memory-system, diagram
├── demo-app/                     # worked example: a real .doruk/ mid-flight
└── web/index.html                # interactive showcase (GitHub Pages)
```

---

## License & attribution

MIT — see [`LICENSE`](LICENSE). These are my own skills, built for Claude Code, except
`skills/understanding/explain-diff-html` ([external, credit Geoffrey Litt](https://gist.github.com/geoffreylitt/a29df1b5f9865506e8952488eac3d524)).
The delegation skills orchestrate external CLIs I did not build (OpenAI Codex, Google Gemini), and
`skills/legacy/ship` composed the third-party *superpowers* collection (now disabled) before it was
superseded by `orchestrate`. Full honesty on what's mine and what isn't: [`PROVENANCE.md`](PROVENANCE.md).
