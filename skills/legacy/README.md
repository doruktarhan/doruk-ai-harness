# Legacy skills

Kept for reference, not installed. Written for pre-Fable models that needed a scripted
spec → plan → subagent pipeline. With Fable 5.1 / Opus 5 class models, plan and delegate
directly (`orchestrate`) and discuss with `discuss`. See `skills/meta/lean-instructions`
for why: OpenAI's Sept 2026 guidance on trimming scaffolding for capable models.

- `ship/` — spec → codex review → plan → simplification → execute → PR loop. Depended on the
  superpowers plugin (now disabled). Superseded by `orchestrate`.
- `align/` — one-question-at-a-time design grilling. Folded into `discuss` as an optional
  structured-question round.
- `codex-feedback-planning/`, `codex-task-delegator/` — merged into `skills/delegation/codex`
  (one router, two reference files, no confirmation turn on explicit requests).
