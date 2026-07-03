#!/usr/bin/env bash
#
# install.sh — install the doruk-ai-harness skills into ~/.claude/skills/
#
# PREFERRED INSTALL: inside Claude Code, use the plugin route (see below).
# The plugin's .claude-plugin/plugin.json declares every skill in its skills[]
# manifest, so `/plugin install` loads all 13 natively despite the category
# subdirs. This script is the FALLBACK for offline use or non-Claude-Code
# harnesses that read ~/.claude/skills/ directly.
#
# The skills are organized into category directories for browsing:
#   skills/workflow/   skills/state-memory/   skills/delegation/   skills/understanding/
# Each LEAF (skills/<block>/<name>/, containing a SKILL.md) is a real skill.
# Claude Code discovers skills by name, not by category, so this script
# FLATTENS the categories: every leaf is copied into ~/.claude/skills/<name>/.
#
# Idempotent: safe to re-run. It overwrites only the harness's own skills and
# never deletes or touches unrelated skills you already have installed.
#
# Usage:
#   ./install.sh             Install (copy all leaf skills into ~/.claude/skills/)
#   ./install.sh --dry-run   Show what would happen, change nothing
#   ./install.sh --help      Show this help
#
# Alternatives (no script needed):
#   Manual copy:  mkdir -p ~/.claude/skills && cp -R skills/*/*/ ~/.claude/skills/
#   Plugin route (preferred, from inside Claude Code) —
#       /plugin marketplace add doruktarhan/doruk-ai-harness
#       /plugin install doruk-ai-harness@doruk-ai-harness
#     (loads all 13 skills natively via the plugin.json skills[] manifest.)
#
set -euo pipefail

# --- locate this repo's skills/ regardless of where the script is called from ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/skills"
DEST_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

DRY_RUN=0

usage() {
  sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) DRY_RUN=1 ;;
    --help|-h)    usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; echo "Try: $0 --help" >&2; exit 2 ;;
  esac
done

if [ ! -d "$SRC_DIR" ]; then
  echo "error: skills/ not found at $SRC_DIR" >&2
  echo "Run this script from inside a doruk-ai-harness checkout." >&2
  exit 1
fi

# Collect the LEAF skill folders to install. A leaf is skills/<block>/<name>/
# that contains a SKILL.md. We track both the leaf path (source) and the bare
# skill name (flattened destination), and guard against duplicate names across
# different category dirs.
names=()
srcs=()
seen_names=""

for block in "$SRC_DIR"/*/; do
  [ -d "$block" ] || continue
  for leaf in "$block"*/; do
    [ -d "$leaf" ] || continue
    [ -f "${leaf}SKILL.md" ] || continue
    name="$(basename "$leaf")"

    # Duplicate-name guard: flattening means two categories can't both define <name>.
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
echo "  source: $SRC_DIR  (category dirs flattened)"
echo "  target: $DEST_DIR"
echo "  skills: ${#names[@]} (${names[*]})"
[ "$DRY_RUN" -eq 1 ] && echo "  mode:   DRY RUN (no changes will be made)"
echo

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$DEST_DIR"
fi

i=0
while [ "$i" -lt "${#names[@]}" ]; do
  name="${names[$i]}"
  src="${srcs[$i]}"
  dest="$DEST_DIR/$name"
  i=$((i + 1))

  if [ -d "$dest" ]; then
    action="update"
  else
    action="install"
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  would $action  $name  (from ${src#$SCRIPT_DIR/})"
    continue
  fi

  # Idempotent overwrite: remove our previous copy of THIS skill, then copy fresh.
  # Only ever touches the named skill folder — never the rest of ~/.claude/skills/.
  rm -rf "$dest"
  cp -R "$src" "$dest"
  echo "  $action  $name"
done

echo
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run complete. Re-run without --dry-run to apply."
else
  echo "Done. ${#names[@]} skill(s) installed to $DEST_DIR"
  echo "Start a new Claude Code session (or restart) to pick them up."
fi
