# Provenance & attribution

Honest accounting of what's mine and what isn't.

## What's mine

Every skill in [`skills/`](skills/) — except `skills/understanding/explain-diff-html` — plus the
architecture in [`docs/`](docs/), the worked example in [`demo-app/`](demo-app/), and the showcase
page in [`web/`](web/) are my own work, designed and written by me (Doruk Tarhan) for Claude Code.

## What's not mine

- **`codex`** (merged from the former `codex-feedback-planning` and `codex-task-delegator`,
  now kept in `skills/legacy/` for reference) orchestrates the **OpenAI Codex CLI**. The
  skill (prompts, invocation, worktree sandboxing, diff review flow) is mine; Codex itself
  isn't.
- **`gemini-delegate`** orchestrates the **Google Gemini CLI** the same way — mine is the skill, not
  the CLI.
- **`skills/browser/jev-browser`** and its `jb` CLI are mine: the skill, the browser runtime, the
  action enumeration, and the safety stops. The **Jev** model that picks each action is TypeSafe
  AI's, called through Vercel AI Gateway or TypeSafe's API. Form typing goes through a small
  Gemini model on the same Gateway. `jb` runs on Microsoft's Playwright.
- **`skills/understanding/explain-diff-html`** is imported verbatim from a
  [gist by Geoffrey Litt](https://gist.github.com/geoffreylitt/a29df1b5f9865506e8952488eac3d524) —
  packaged as a Claude Code skill, prompt unchanged.
- **`skills/meta/lean-instructions`** distills OpenAI's September 2026 blog post *"Rethinking
  skills and prompts for GPT-6 Astra"* into a set of rules and an audit procedure for this
  repo (summarized honestly in its `references/astra-2026-09.md`). The source guidance is
  OpenAI's; the rules as written and the audit procedure are mine.
- **`skills/legacy/ship`** (kept for reference, not installed) composed the third-party
  **superpowers** collection (brainstorm/plan/execute loop) with my own
  `codex-feedback-planning` for cross-model review. That superpowers dependency is now
  disabled and `ship` is superseded by planning and delegating directly through
  `orchestrate` — see `skills/legacy/README.md`.

## License

MIT — see [`LICENSE`](LICENSE). The external CLIs and skills above are governed by their own
licenses, not this one.
