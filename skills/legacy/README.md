# Legacy skills

Kept for reference, not installed. Written for pre-Fable models that needed a scripted
spec → plan → subagent pipeline. With Fable 5.1 / Opus 5 class models, plan and delegate
directly (`orchestrate`) and discuss with `discuss`. See `skills/meta/lean-instructions`
for why: OpenAI's Sept 2026 guidance on trimming scaffolding for capable models.

- `ship/` — spec → codex review → plan → simplification → execute → PR loop. Depended on the
  superpowers plugin (now disabled). Superseded by `orchestrate`.
- `align/` — was here as one-question-at-a-time design grilling, briefly folded into
  `discuss` as a structured-question round, and came back (2026-10-19) as
  `skills/workflow/align`, rebuilt on Matt Pocock's `grilling` method. The old text is in
  git history only.
- `codex-feedback-planning/`, `codex-task-delegator/` — merged into `skills/delegation/codex`
  (one router, two reference files, no confirmation turn on explicit requests).
