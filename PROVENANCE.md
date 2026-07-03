# Provenance & attribution

Honest accounting of what's mine and what isn't.

## What's mine

Every skill in [`skills/`](skills/) — except `skills/understanding/explain-diff-html` — plus the
architecture in [`docs/`](docs/), the worked example in [`demo-app/`](demo-app/), and the showcase
page in [`web/`](web/) are my own work, designed and written by me (Doruk Tarhan) for Claude Code.

## What's not mine

- **`codex-feedback-planning`** and **`codex-task-delegator`** orchestrate the **OpenAI Codex CLI**.
  The skill (prompts, invocation, worktree sandboxing, diff review flow) is mine; Codex itself isn't.
- **`gemini-delegate`** orchestrates the **Google Gemini CLI** the same way — mine is the skill, not
  the CLI.
- **`ship`** composes the third-party **superpowers** collection (brainstorm/plan/execute loop) and
  **ponytail** (simplification pass), plus my own `codex-feedback-planning` for cross-model review.
  The orchestration and the human-gated pipeline are mine; superpowers and ponytail are not.
- **`skills/understanding/explain-diff-html`** is imported verbatim from a
  [gist by Geoffrey Litt](https://gist.github.com/geoffreylitt/a29df1b5f9865506e8952488eac3d524) —
  packaged as a Claude Code skill, prompt unchanged.

## License

MIT — see [`LICENSE`](LICENSE). The external CLIs and skills above are governed by their own
licenses, not this one.
