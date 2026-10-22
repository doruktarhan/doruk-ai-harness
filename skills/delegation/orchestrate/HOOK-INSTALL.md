# Installing the coordinator-hook

`SessionStart` hook: points Fable/Opus sessions at `orchestrate`; silent for Sonnet/Haiku
and subagents. `install.sh` uses `cp -R` on the whole leaf folder, so `coordinator-hook.sh`
travels with `SKILL.md` automatically — no manual copy needed after `./install.sh`.

## Install

Merge into user-level `~/.claude/settings.json` `hooks` key. Use an absolute path — the
script lives in the user skill dir, so `$CLAUDE_PROJECT_DIR` (valid but meaningless here)
doesn't help. Settings hot-reload, but `SessionStart` only fires at session start — start a
new session to observe it; `/hooks` confirms registration.

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [
        { "type": "command", "command": "/Users/you/.claude/skills/orchestrate/coordinator-hook.sh" }
      ] }
    ]
  }
}
```

## Uninstall

Remove the `SessionStart` block above from `~/.claude/settings.json`.

## Known blind spots
- Default-model launch with no `model` key anywhere → stays silent rather than guessing.
- Mid-session `/model` switch isn't seen (hook only runs at start). Fine for a soft pointer.
- By design, not a bug: a stale `--model` argv surviving a `/clear` or `/compact` can
  re-emit the old pointer. Kept intentionally — losing pointer re-injection right after a
  context wipe (where it's most useful) is a worse trade than a rare stale soft pointer.

# Installing the foreman-hook

`PreToolUse` hook on the `Agent` tool: when a spawn's model is Fable or Opus and its prompt
opens with no `Role:` line, prepends the foreman role line to the prompt via `updatedInput`.
Silent for Sonnet/Haiku, for `Role: executor.` prompts, and for Explore/Plan/statusline-setup/
claude-code-guide. Not a `SubagentStart` hook because that event's stdin carries no model and
no prompt (2.1.303); the header of `foreman-hook.sh` has the measurements. Needs `python3`.

```json
{ "hooks": { "PreToolUse": [
  { "matcher": "Agent|Task", "hooks": [
    { "type": "command", "command": "/Users/you/.claude/skills/orchestrate/foreman-hook.sh", "timeout": 10 }
  ] }
] } }
```
