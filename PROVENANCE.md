# Provenance & attribution

Honest accounting of what's mine, what isn't, and where the lines are. I'd rather be precise
than impressive.

## What's mine

Every skill in [`skills/`](skills/), the architecture in [`docs/`](docs/), the worked example in
[`demo-app/`](demo-app/), and the showcase page in [`web/`](web/) are **my own work** — designed,
written, and refined by me (Doruk Tarhan) for use with **Claude Code**, Anthropic's CLI. The
ideas they encode (the four-beat loop, the committed `.doruk/` memory layer, the
reference-don't-duplicate discipline, the worktree-isolated delegation pattern) are the conventions
I actually use day to day, distilled into reusable form.

**Nothing here is copied from anyone else's skill collection or repo.** No code, prompts, or
templates were lifted from third-party projects. Where these skills resemble common practice (git
worktrees, GitHub issue workflows), that's convergence on standard tooling, not derivation.

## What's NOT mine — and how these skills relate to it

Two categories here: external **CLIs** that my delegation skills orchestrate, and external
**skills** that my `ship` workflow composes. In both cases I wrote the orchestration; the
underlying tools, models, and skills belong to others.

### External CLIs the delegation skills orchestrate

| Skill | Orchestrates | Built by | What I actually wrote |
|---|---|---|---|
| `codex-feedback-planning` | **OpenAI Codex CLI** (`codex`) | OpenAI | The skill that drives it as a read-only plan reviewer — prompts, invocation flags, result handling. |
| `codex-task-delegator` | **OpenAI Codex CLI** (`codex`) | OpenAI | The skill that drives it as a worktree-sandboxed implementer — context-packing, invocation, diff review/merge flow. |
| `gemini-delegate` | **Google Gemini CLI** (`gemini`) | Google | The skill that drives it as either a read-only consultant or a worktree implementer. |

To be unambiguous: **I orchestrate Codex and Gemini. I did not create the Codex CLI, the Gemini
CLI, or the underlying models.** These are external dependencies installed and authenticated
separately by the user (`npm i -g @openai/codex`, `npm i -g @google/gemini-cli`). My skills are
the glue and the operating discipline around them — when to reach for them, how to brief them, how
to sandbox their writes in a git worktree, and how to review and merge the result. Describing this
as "I built a Codex/Gemini integration" would be accurate; describing it as "I built Codex/Gemini"
would not, and I'm not claiming that.

### External skills the `ship` workflow composes

The `workflow/ship` skill **composes third-party pieces honestly**: it builds on the
**superpowers** brainstorming / plan-writing / execution loop and the **ponytail** simplification
skill, plus Doruk's own `codex-feedback-planning` for cross-model review. It is an
**orchestrator** — it sequences and gates skills it does not own. The orchestration *and* the
always-ship-quality, human-gated pipeline — the order of beats, the human-in-the-loop gate at
every decision, the always-review-quality discipline, the `.doruk/`-not-in-the-PR rule, and the
do-not-cut safety list for the simplification pass — are **Doruk's**. The composed tools are
credited here and in the `ship` skill's own README and are **not** his.

| Beat in `ship` | Driven through | Built by | What I actually wrote |
|---|---|---|---|
| Brainstorm / plan-writing / execution | the **superpowers** skill collection | a third party (not me) | The orchestration that sequences and human-gates these skills inside the loop. |
| Simplification / over-engineering review | the **ponytail** skill | a third party (not me) | The work-type judgment for when to run it and the do-not-cut list that makes it safe. |
| Cross-model spec & plan review | my own `codex-feedback-planning` (above) | orchestration mine; Codex OpenAI's | See the CLI table above. |

To be unambiguous: **the superpowers collection and the ponytail skill are not my work.** `ship`
calls them; it does not contain them. If they aren't installed, `ship` falls back to plain
built-in equivalents and says so, rather than implying the gate ran. Describing `ship` as "an
orchestrator I built that composes superpowers and ponytail" is accurate; describing those skills
as mine would not be.

## Tools and platforms referenced

- **Claude Code** (Anthropic) — the host these skills run in. I build *for* it; I didn't build it.
- **git worktrees** — a standard git feature. The isolation pattern is mine; the primitive is git's.
- **GitHub CLI (`gh`)** — used by the `ship` workflow's PR step. Standard tooling, not mine.
- **superpowers** (skill collection) and **ponytail** (skill) — third-party Claude Code skills
  that `ship` composes. Not mine; credited above and relied on as optional dependencies.

## What I am NOT claiming

- I am **not** claiming authorship of the OpenAI Codex CLI or the Google Gemini CLI.
- I am **not** claiming any third-party Claude Code skill, plugin, or skill collection as my own —
  including the **superpowers** collection and the **ponytail** skill that the `ship` workflow
  composes. `ship` orchestrates them; it does not contain them, and they remain their authors' work.
- I am **not** inventing capabilities or metrics. The skills do exactly what their `SKILL.md`
  files describe — no more.

## License

This work is released under the MIT License — see [`LICENSE`](LICENSE). The external CLIs and
models it orchestrates are governed by their own respective licenses and terms, not this one.
