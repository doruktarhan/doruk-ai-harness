# The orchestrate hooks

Three scripts, four registrations. Each needs `python3`, prints nothing when it has nothing
to say, and exits 0 on any error.

| Where | Event | Script | Effect |
|-------|-------|--------|--------|
| Project `.claude/settings.json` | `SessionStart` | `main-hook.sh` | Puts `roles/main.md` into every top-level session of that project, at start, resume, clear and after compaction. Silent for subagents. No model check (see the script header). |
| User `~/.claude/settings.json` | `PreToolUse`, matcher `Agent\|Task` | `foreman-hook.sh` | Main-session spawn on Opus or Fable: prepends `roles/foreman.md`, unless the prompt opens with `Role: executor` or `Role: leaf`. Fable spawn from anyone: effort unset becomes `medium`, `xhigh`/`max` become `high`. Names are left alone. |
| User | `UserPromptSubmit` | `depth-gauge.sh --hook` | On each message from Doruk and each agent-finished notice: one line per agent that crossed 250k or 350k since the last warning. |
| User | `PreToolUse`, matcher `SendMessage` | `depth-gauge.sh --hook` | When the main session messages an agent at 350k or more: a reminder, every time. |

## Install

From a checkout of the harness repo:

```bash
./install.sh --hooks                          # skills + the three user-level registrations
./install.sh --project-hook /path/to/project  # opt one project in to the main-session rules
```

Both are safe to run twice and back up the settings file they change. By hand, the project
file is (the whole file, if the project has none):

```json
{ "hooks": { "SessionStart": [ { "hooks": [
  { "type": "command", "command": "\"$HOME/.claude/skills/orchestrate/main-hook.sh\"", "timeout": 10 } ] } ] } }
```

and the user file gets these merged into `hooks`:

```json
{ "hooks": {
  "UserPromptSubmit": [ { "hooks": [
    { "type": "command", "command": "\"$HOME/.claude/skills/orchestrate/depth-gauge.sh\" --hook", "timeout": 10 } ] } ],
  "PreToolUse": [
    { "matcher": "Agent|Task", "hooks": [
      { "type": "command", "command": "\"$HOME/.claude/skills/orchestrate/foreman-hook.sh\"", "timeout": 10 } ] },
    { "matcher": "SendMessage", "hooks": [
      { "type": "command", "command": "\"$HOME/.claude/skills/orchestrate/depth-gauge.sh\" --hook", "timeout": 10 } ] }
  ]
} }
```

Settings hot-reload, but `SessionStart` fires only at session start, so open a new session to
see it; `/hooks` confirms registration.

## Check that they fire

1. New session in the project, ask: "quote the first sentence of the orchestration rules in
   your context". Expected: "Orchestration rules for the main session."
2. Spawn an Opus agent with the prompt "Role: tester. Quote the first eight words of your
   prompt." Expected: "Role: foreman. If the brief below names a".
3. `~/.claude/skills/orchestrate/depth-gauge.sh` in that session prints the agent and its size.

## Known limits

- A spawn with no `model` inherits its caller's model, which the hook reads from the caller's
  transcript. In the first turn of a session there is no transcript line yet, so an unset
  first spawn gets no foreman text. The main rules say to set `model` on every spawn.
- The depth warnings are remembered in `$TMPDIR/orchestrate-depth-<session-id>.json`. Delete
  it to see them again.
- `permissionDecision: allow` is returned with a rewritten spawn, so a rewritten Agent call is
  not prompted for. The old hook did the same.

## Uninstall

`./install.sh --uninstall-hooks` removes the three user entries and
`./install.sh --remove-project-hook /path/to/project` the project one; or delete the four
entries by hand. The role files then load only when someone invokes the skill.
