#!/usr/bin/env bash
#
# install.sh — install the doruk-ai-harness skills, and optionally the orchestration hooks.
#
# Usage:
#   ./install.sh                       Copy every skill into ~/.claude/skills/
#   ./install.sh --hooks               Same, then register the orchestration hooks in
#                                      ~/.claude/settings.json (foreman rules + Fable effort
#                                      cap on agent spawns, context warnings at 250k / 350k)
#   ./install.sh --project-hook DIR    Opt one project in: add the main-session rules hook
#                                      (SessionStart) to DIR/.claude/settings.json.
#                                      Changes nothing else; combine with --hooks if wanted.
#   ./install.sh --remove-project-hook DIR
#                                      Take that hook out of DIR/.claude/settings.json
#   ./install.sh --uninstall-hooks     Remove the hooks from ~/.claude/settings.json
#   ./install.sh --uninstall           Remove the hooks and the harness's skill folders
#   ./install.sh --dry-run             With any of the above: print what would change
#   ./install.sh --help                Show this help
#
# Environment:
#   CLAUDE_HOME         Claude Code's config folder (default: ~/.claude)
#   CLAUDE_SKILLS_DIR   Where skills go (default: $CLAUDE_HOME/skills)
#
# Idempotent: safe to re-run. Installing replaces the folders named after this harness's
# skills; --uninstall removes only folders this script installed. Only this harness's own
# hook entries are added or removed, and a settings file is backed up beside itself before
# it is changed.
# The hooks need python3.
#
# --- end of help ---
#
# Layout: skills live in category directories for browsing (skills/workflow/,
# skills/state-memory/, skills/delegation/, skills/understanding/, skills/meta/). Each LEAF
# (skills/<block>/<name>/ with a SKILL.md) is a real skill. Claude Code discovers skills by
# name, so this script FLATTENS the categories: every leaf is copied to
# <skills dir>/<name>/. skills/legacy/ is excluded on purpose (reference only; see
# skills/legacy/README.md).
#
# A destination that is a symlink is left alone, on install and on uninstall: that is the
# maintainer's own layout, where ~/.claude/skills/<name> points back into this checkout.
#
# Other routes for the skills (no hooks):
#   Plugin:  /plugin marketplace add doruktarhan/doruk-ai-harness
#            /plugin install doruk-ai-harness@doruk-ai-harness
#   Manual:  mkdir -p ~/.claude/skills && cp -R skills/*/*/ ~/.claude/skills/
# The hooks and the role files point at ~/.claude/skills/orchestrate/, so the orchestration
# setup needs this script's copy route.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/skills"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$CLAUDE_DIR/skills}"
SETTINGS="$CLAUDE_DIR/settings.json"

# Dropped into every skill folder this script copies; --uninstall removes only folders that
# carry it, so a same-named skill of your own is never deleted.
MARKER=".installed-by-doruk-ai-harness"

DRY_RUN=0
DO_HOOKS=0
UNINSTALL_HOOKS=0
UNINSTALL=0
PROJECT_ADD=""
PROJECT_REMOVE=""

usage() {
  sed -n '2,/^# --- end of help ---$/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run|-n)       DRY_RUN=1 ;;
    --hooks)            DO_HOOKS=1 ;;
    --uninstall-hooks)  UNINSTALL_HOOKS=1 ;;
    --uninstall)        UNINSTALL=1 ;;
    --project-hook|--remove-project-hook)
      if [ "$#" -lt 2 ]; then echo "error: $1 needs a project directory" >&2; exit 2; fi
      if [ ! -d "$2" ]; then echo "error: not a directory: $2" >&2; exit 2; fi
      if [ "$1" = "--project-hook" ]; then PROJECT_ADD="$(cd "$2" && pwd)"
      else PROJECT_REMOVE="$(cd "$2" && pwd)"; fi
      shift ;;
    --help|-h)          usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $0 --help" >&2; exit 2 ;;
  esac
  shift
done

REMOVING=0
if [ "$UNINSTALL" -eq 1 ] || [ "$UNINSTALL_HOOKS" -eq 1 ]; then REMOVING=1; fi
if [ "$REMOVING" -eq 1 ] && [ "$DO_HOOKS" -eq 1 ]; then
  echo "error: --hooks cannot be combined with --uninstall or --uninstall-hooks" >&2; exit 2
fi
if [ "$REMOVING" -eq 1 ] && [ -n "$PROJECT_ADD" ]; then
  echo "error: --project-hook cannot be combined with --uninstall or --uninstall-hooks" >&2; exit 2
fi

# Copy the skills on a plain run and with --hooks; a project-hook-only run copies nothing.
DO_SKILLS=1
if [ "$REMOVING" -eq 1 ]; then DO_SKILLS=0; fi
if [ "$DO_HOOKS" -eq 0 ] && [ -n "$PROJECT_ADD$PROJECT_REMOVE" ]; then DO_SKILLS=0; fi

if [ ! -d "$SRC_DIR" ]; then
  echo "error: skills/ not found at $SRC_DIR" >&2
  echo "Run this script from inside a doruk-ai-harness checkout." >&2
  exit 1
fi

NEEDS_PY=0
if [ "$DO_HOOKS" -eq 1 ] || [ "$REMOVING" -eq 1 ] || [ -n "$PROJECT_ADD$PROJECT_REMOVE" ]; then NEEDS_PY=1; fi
if [ "$NEEDS_PY" -eq 1 ] && ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is needed to edit settings.json (and by the hooks themselves)." >&2
  exit 1
fi

# The hook commands are written with a literal $HOME where possible, so a committed project
# settings file works on every machine.
case "$DEST_DIR" in
  "$HOME"/*) HOOK_PREFIX="\$HOME/${DEST_DIR#"$HOME"/}/orchestrate" ;;
  *)         HOOK_PREFIX="$DEST_DIR/orchestrate" ;;
esac

# --- collect the leaf skills ---
# A leaf is skills/<block>/<name>/ with a SKILL.md. Names must be unique across categories,
# because flattening would otherwise clobber one of them.
names=()
srcs=()
seen_names=""

for block in "$SRC_DIR"/*/; do
  [ -d "$block" ] || continue
  [ "$(basename "$block")" = "legacy" ] && continue
  for leaf in "$block"*/; do
    [ -d "$leaf" ] || continue
    [ -f "${leaf}SKILL.md" ] || continue
    name="$(basename "$leaf")"
    case " $seen_names " in
      *" $name "*)
        echo "error: duplicate skill name '$name' across category dirs — flattening would clobber it." >&2
        echo "       Rename one of the leaf folders so names are unique across skills/*/." >&2
        exit 1
        ;;
    esac
    seen_names="$seen_names $name"
    names+=("$name")
    srcs+=("${leaf%/}")
  done
done

if [ "${#names[@]}" -eq 0 ]; then
  echo "error: no leaf skills (skills/*/*/ folders with a SKILL.md) found under $SRC_DIR" >&2
  exit 1
fi

echo "doruk-ai-harness installer"
echo "  skills dir: $DEST_DIR"
echo "  settings:   $SETTINGS"
[ "$DRY_RUN" -eq 1 ] && echo "  mode:       DRY RUN (no changes will be made)"
echo

# --- settings.json editing ---
# edit_settings FILE ACTION   ACTION: add-user | remove-user | add-project | remove-project
# Only this harness's entries are added or removed (matched by ".../orchestrate/<script>").
edit_settings() {
  HARNESS_DRY="$DRY_RUN" python3 - "$1" "$2" "$HOOK_PREFIX" <<'PY'
import json, os, re, shutil, sys, tempfile, time

path, action, prefix = sys.argv[1:4]
dry = os.environ.get("HARNESS_DRY") == "1"
OURS = ("foreman-hook.sh", "depth-gauge.sh", "main-hook.sh", "coordinator-hook.sh")


def is_ours(hook, scripts):
    """True when the hook's command is exactly one of this harness's scripts: a path ending
    in skills/orchestrate/<script>, optionally quoted, with no argument or only --hook."""
    if not isinstance(hook, dict):
        return False
    m = re.match(r"""^\s*(["']?)(\S*/skills/orchestrate/([\w.-]+))\1(\s+--hook)?\s*$""",
                 hook.get("command") or "")
    return bool(m) and m.group(3) in scripts

if os.path.exists(path):
    try:
        with open(path) as fh:
            before = fh.read()
        settings = json.loads(before) if before.strip() else {}
    except Exception as exc:
        sys.exit("error: cannot parse %s (%s). Nothing was changed." % (path, exc))
    if not isinstance(settings, dict):
        sys.exit("error: %s is not a JSON object. Nothing was changed." % path)
else:
    before, settings = None, {}

hooks = settings.get("hooks", {})
if not isinstance(hooks, dict) or not all(isinstance(v, list) for v in hooks.values()):
    sys.exit("error: \"hooks\" in %s is not in the expected shape. Nothing was changed." % path)
log = []


def cmd(script, arg=""):
    return '"%s/%s"%s' % (prefix, script, arg)


def entry(script, arg=""):
    return {"type": "command", "command": cmd(script, arg), "timeout": 10}


def has(event, script, matcher=None):
    for group in hooks.get(event, []):
        if not isinstance(group, dict):
            continue
        if matcher is not None and group.get("matcher") != matcher:
            continue
        if any(is_ours(h, (script,)) for h in group.get("hooks") or []):
            return True
    return False


def drop(event, scripts):
    """Remove our hook entries from one event; drop groups and events left empty."""
    kept, removed = [], 0
    for group in hooks.get(event, []):
        if not isinstance(group, dict) or not isinstance(group.get("hooks"), list):
            kept.append(group)
            continue
        inner = [h for h in group["hooks"] if not is_ours(h, scripts)]
        removed += len(group["hooks"]) - len(inner)
        if len(inner) == len(group["hooks"]):
            kept.append(group)
        elif inner:
            kept.append(dict(group, hooks=inner))
    if removed:
        log.append("remove %d entr%s from %s" % (removed, "y" if removed == 1 else "ies", event))
        if kept:
            hooks[event] = kept
        else:
            hooks.pop(event, None)


def add(event, needle, group, matcher=None):
    if has(event, needle, matcher):
        log.append("already there: %s%s -> %s" % (event, " [%s]" % matcher if matcher else "", needle))
        return
    hooks.setdefault(event, []).append(group)
    log.append("add %s%s -> %s" % (event, " [%s]" % matcher if matcher else "",
                                   group["hooks"][0]["command"]))


if action == "add-user":
    # v3 registered a coordinator hook at user level; v4 replaced it with the per-project hook.
    drop("SessionStart", ("coordinator-hook.sh",))
    add("UserPromptSubmit", "depth-gauge.sh",
        {"hooks": [entry("depth-gauge.sh", " --hook")]})
    add("PreToolUse", "foreman-hook.sh",
        {"matcher": "Agent|Task", "hooks": [entry("foreman-hook.sh")]}, "Agent|Task")
    add("PreToolUse", "depth-gauge.sh",
        {"matcher": "SendMessage", "hooks": [entry("depth-gauge.sh", " --hook")]}, "SendMessage")
elif action == "add-project":
    add("SessionStart", "main-hook.sh", {"hooks": [entry("main-hook.sh")]})
elif action == "remove-user":
    for event in list(hooks):
        drop(event, OURS)
elif action == "remove-project":
    drop("SessionStart", ("main-hook.sh",))
else:
    sys.exit("error: unknown action %s" % action)

if hooks:
    settings["hooks"] = hooks
else:
    settings.pop("hooks", None)
after = json.dumps(settings, indent=2) + "\n"
changed = (before is None and bool(settings)) or (before is not None and json.loads(before or "{}") != settings)

for line in log:
    print("  %s%s" % ("would " if dry and not line.startswith("already") else "", line))
if not changed:
    print("  no change: %s" % path)
elif dry:
    print("  would write %s" % path)
else:
    path = os.path.realpath(path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if before is not None:
        backup = base = "%s.bak-%s" % (path, time.strftime("%Y%m%d-%H%M%S"))
        n = 1
        while os.path.exists(backup):
            n += 1
            backup = "%s-%d" % (base, n)
        shutil.copy2(path, backup)
        print("  backup: %s" % backup)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".settings-", suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as fh:
            fh.write(after)
            fh.flush()
            os.fsync(fh.fileno())
        if before is not None:
            shutil.copymode(path, tmp)
        else:
            os.chmod(tmp, 0o644)
        os.replace(tmp, path)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise
    print("  wrote %s" % path)
PY
}

# --- uninstall ---
if [ "$REMOVING" -eq 1 ]; then
  echo "Removing the orchestration hooks from the user settings"
  edit_settings "$SETTINGS" remove-user
  if [ -n "$PROJECT_REMOVE" ]; then
    echo "Removing the main-session hook from $PROJECT_REMOVE"
    edit_settings "$PROJECT_REMOVE/.claude/settings.json" remove-project
  fi
  if [ "$UNINSTALL" -eq 1 ]; then
    echo "Removing the harness's skill folders from $DEST_DIR"
    for name in "${names[@]}"; do
      dest="$DEST_DIR/$name"
      if [ -L "$dest" ]; then
        echo "  left alone (symlink)  $name"
      elif [ -d "$dest" ] && [ ! -f "$dest/$MARKER" ]; then
        echo "  left alone (not installed by this script)  $name"
      elif [ -d "$dest" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then echo "  would remove  $name"
        else rm -rf "$dest"; echo "  removed  $name"; fi
      fi
    done
  fi
  echo
  echo "Done. Project hooks are per project: ./install.sh --remove-project-hook DIR"
  exit 0
fi

# --- skills ---
if [ "$DO_SKILLS" -eq 1 ]; then
  echo "Skills: ${#names[@]} (${names[*]})"
  [ "$DRY_RUN" -eq 0 ] && mkdir -p "$DEST_DIR"
  i=0
  while [ "$i" -lt "${#names[@]}" ]; do
    name="${names[$i]}"
    src="${srcs[$i]}"
    dest="$DEST_DIR/$name"
    i=$((i + 1))

    if [ -L "$dest" ]; then
      echo "  left alone (symlink)  $name"
      continue
    fi
    if [ -d "$dest" ]; then action="update"; else action="install"; fi
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "  would $action  $name  (from ${src#"$SCRIPT_DIR"/})"
      continue
    fi
    # Idempotent overwrite of THIS skill's folder only.
    rm -rf "$dest"
    cp -R "$src" "$dest"
    : > "$dest/$MARKER"
    echo "  $action  $name"
  done
  if [ "$DRY_RUN" -eq 0 ] && [ ! -L "$DEST_DIR/orchestrate" ]; then
    chmod +x "$DEST_DIR"/orchestrate/*.sh "$DEST_DIR"/codex/scripts/*.sh 2>/dev/null || true
  fi
  echo
fi

# --- hooks ---
if [ "$DO_HOOKS" -eq 1 ]; then
  echo "Orchestration hooks (user settings)"
  edit_settings "$SETTINGS" add-user
  echo
fi

if [ -n "$PROJECT_ADD" ]; then
  if [ "$DRY_RUN" -eq 0 ] && [ ! -f "$DEST_DIR/orchestrate/main-hook.sh" ]; then
    echo "error: $DEST_DIR/orchestrate/main-hook.sh is missing. Run ./install.sh --hooks first." >&2
    exit 1
  fi
  echo "Main-session hook for $PROJECT_ADD"
  edit_settings "$PROJECT_ADD/.claude/settings.json" add-project
  echo
fi

if [ -n "$PROJECT_REMOVE" ]; then
  echo "Removing the main-session hook from $PROJECT_REMOVE"
  edit_settings "$PROJECT_REMOVE/.claude/settings.json" remove-project
  echo
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run complete. Re-run without --dry-run to apply."
else
  echo "Done. Start a new Claude Code session to pick up the changes."
  if [ "$DO_SKILLS" -eq 1 ] && [ "$DO_HOOKS" -eq 0 ]; then
    echo "Orchestration hooks are separate: ./install.sh --hooks"
  fi
  if [ "$DO_HOOKS" -eq 1 ] && [ -z "$PROJECT_ADD" ]; then
    echo "Main-session rules are opt-in per project: ./install.sh --project-hook /path/to/project"
  fi
fi
