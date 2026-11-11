---
name: orchestrate
description: Use when the orchestration rules are not already in your context and you are about
  to hand work to subagents, or when changing those rules or their hooks.
user_invocable: true
metadata:
  author: doruktarhan
  version: "4.0.0"
---

# Orchestrate

The rules live in two role files, and hooks load them, so most sessions never need this page.

| You are | Your rules | Loaded by |
|---------|-----------|-----------|
| The main session (talks to Doruk) | `roles/main.md` | `main-hook.sh` at session start, resume and after compaction, in projects that register it |
| A foreman (an Opus or Fable agent the main session spawned) | `roles/foreman.md` | `foreman-hook.sh`, prepended to the spawn prompt |
| A helper (spawned by a foreman, or a Sonnet agent) | The brief you were given | nothing |

If your role's text is not in your context, read its file now and follow it.

## Who does what

| Work | Who | Model |
|------|-----|-------|
| Intake, routing, relaying | Main session | Opus 5.5 unless Doruk switches it |
| Config, tiny change, check, lookup | One agent, no foreman | Sonnet |
| Low-logic build | Foreman | Opus |
| Scoped build, design | Foreman | Fable at `medium`; `high` rarely; nothing above |
| Labor inside a build | Foreman's helpers | Sonnet mostly, Opus where it needs judgement |
| Review before merge | Run by the foreman | Codex Sol; Astra for money path and new-mechanism specs |

## References

- `references/splitting.md`: when to split a big order into pieces.
- `references/watchdog.md`: `agent-watch.py` for unattended nights.
- `references/rationale.md`: why each rule exists, incidents, Codex command lines.
- `HOOK-INSTALL.md`: the three hooks and how to check they fire.
- `depth-gauge.sh`: context size of each live agent, measured from its transcript.

## Changing the rules

Edit the role file; the hooks read it on every run, so there is nothing to reinstall. Keep
each role file under about 500 words; they load on every session start and every foreman spawn.

Done when the role text is in your context and you are following it.
