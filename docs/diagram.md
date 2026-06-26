# Harness at a glance

The headline is the **workflow**: a from-scratch pipeline that takes a task `discuss → align → ship`,
keeps a human in the loop at every decision, and gates the result through multiple models so what
ships is the highest-quality version. Two supporting blocks — **state &amp; memory** and **delegation** —
power that pipeline. Read [`system-and-flow.md`](./system-and-flow.md) for the full description.

```mermaid
flowchart TB
    subgraph WF["WORKFLOW · from scratch → review-ready PR (skills/workflow/)"]
        direction LR
        D["<b>discuss</b><br/><i>loose, divergent exploration<br/>before committing to a design</i>"]
        AL["<b>align</b><br/><i>one-question-at-a-time grilling<br/>that converges on a shared design</i>"]
        SH["<b>ship</b><br/><i>drive the aligned spec to a<br/>review-ready PR, quality gates built in</i>"]
        D ==>|"shape found"| AL
        AL ==>|"design agreed"| SH
    end

    HITL["human in the loop at EVERY decision  ·  code quality / complexity / simplification reviewed by MULTIPLE models from different viewpoints"]
    WF -.-> HITL

    subgraph SM["STATE &amp; MEMORY · the committed .doruk/ layer (skills/state-memory/)"]
        direction TB
        SM1["<b>handoff</b><br/><i>STATE.md board + per-feature handoff.md</i>"]
        SM2["<b>feature-organize</b><br/><i>distill feature.md when work ships</i>"]
        SM3["<b>wrap</b><br/><i>end-of-session consistency + updates</i>"]
    end

    subgraph DG["DELEGATION · isolation + cross-model help (skills/delegation/)"]
        direction TB
        DG1["<b>worktree-init</b><br/><i>create isolated worktree, copy local files</i>"]
        DG2["<b>worktree-lifecycle</b><br/><i>build / test / cleanup inside a worktree</i>"]
        DG3["<b>codex-feedback-planning</b><br/><i>Codex as read-only plan reviewer</i>"]
        DG4["<b>codex-task-delegator</b><br/><i>Codex implements in a worktree</i>"]
        DG5["<b>gemini-delegate</b><br/><i>Gemini consultant or implementer</i>"]
    end

    D -.->|orients on| SM1
    SH ==>|runs in| DG
    SH ==>|consults| DG3
    SH ==>|writes back to| SM
    SH ==>|review gate| DG5

    classDef wf fill:#1d4ed8,stroke:#1e3a8a,color:#eff6ff;
    classDef hitl fill:#b45309,stroke:#92400e,color:#fffbeb;
    classDef sm fill:#0e7490,stroke:#155e75,color:#f0fdff;
    classDef dg fill:#7c3aed,stroke:#5b21b6,color:#faf5ff;
    class D,AL,SH wf;
    class HITL hitl;
    class SM1,SM2,SM3 sm;
    class DG1,DG2,DG3,DG4,DG5 dg;
```

**Caption.** The **workflow** block is the pipeline that turns a task into shipped code from scratch.
`discuss` is loose, divergent exploration to find the shape of a task before committing to any design.
`align` is a one-question-at-a-time grilling that converges on a shared design, run before ship. `ship`
drives that aligned spec to a review-ready PR with minimal check-ins. A human stays in the loop at every
decision, and code quality, complexity, and simplification are reviewed by multiple models from different
viewpoints, so what ships is always the highest-quality version.

Two blocks support the pipeline. **State &amp; memory** is the committed `.doruk/` layer: `handoff` keeps the
`STATE.md` board and per-feature handoffs, `feature-organize` distills `feature.md` once work ships, and
`wrap` runs the end-of-session consistency checks and updates. **Delegation** provides isolation and
cross-model help: `worktree-init` and `worktree-lifecycle` create and run isolated git worktrees, while
`codex-feedback-planning`, `codex-task-delegator`, and `gemini-delegate` bring Codex and Gemini in as
reviewers or implementers. `discuss` orients on the state layer, and `ship` runs in worktrees, consults
the delegates as quality gates, and writes results back to `.doruk/`.
