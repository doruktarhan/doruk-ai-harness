---
name: lean-instructions
description: Use when writing or auditing skills, CLAUDE.md/AGENTS.md, hooks, or task prompts for frontier models (Fable, Opus 5, GPT-6 Astra). Cuts babysitting scaffolding that makes capable models slower, tentative, or misfire.
---

# Lean instructions for capable models

Instructions written to babysit weaker models now cost context, trigger the wrong skill,
and make a well-aligned model stop to ask. Source: OpenAI, "Rethinking skills and prompts
for GPT-6 Astra" (2026-09-11), summarized in `references/astra-2026-09.md`.

## Four rules

1. **Narrow triggers.** A skill description says *when* to use it, in one sentence, as short
   as possible. Name the moment ("adding or changing a migration"), not the topic cloud
   ("databases, queries, models, persistence"). Two skills must not fire on the same phrase.
2. **No unconditional pre-reads.** Always-on files (CLAUDE.md, AGENTS.md, session hooks)
   route, they don't mandate. "Use `database.md` for schema changes" beats "before every
   edit read architecture.md, database.md, deployment.md". Generic "always run tests /
   always verify" checklists go; the model already does that.
3. **Permission statements, not caution.** Replace "ask before X" / "NEVER Y" written to
   fence a less-aligned model with the actual boundary: what is safe, what is disposable,
   what needs a human. Reserve hard stops for irreversible actions (merge, delete, prod).
4. **Define done.** Say what finished looks like and whether to continue past the first
   working implementation. The model then stops or keeps going instead of checking in.

## Writing a skill

- Root `SKILL.md` is a router: trigger, decision, pointer to `references/*.md`. Target
  under 600 words; move examples, rationale, and long recipes to references.
- State each rule once. Delete "CRITICAL", "MUST", "NEVER", red-flag tables, and
  BAD/GOOD pairs unless one example genuinely disambiguates.
- End with a Done line.

## Auditing an existing setup

1. List always-on text: CLAUDE.md, AGENTS.md, every SessionStart hook's injected output,
   and the description line of every installed skill (all load every session).
2. For each skill: word count, count of emphasis markers, trigger overlap with siblings,
   presence of a Done criterion.
3. Rank fixes by payoff: delete duplicates first, then narrow triggers, then trim bodies,
   then soften caution language.
4. Apply. Re-measure. Report words removed and skills deleted.

Done: every always-on line earns its place, no two skills share a trigger phrase, every
skill has a Done line, and the audit report lists what changed.
