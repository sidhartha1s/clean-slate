#!/usr/bin/env sh
# clean-slate installer (Linux / macOS).
# Drops SKILL.md into your agent harness's skills directory.
#
#   ./install.sh [claude-code|codex|openclaw|hermes] [--project]
#
# No argument defaults to claude-code, global scope. --project installs into the
# repo-local skills dir of the current directory instead of your home dir.
# Works both from a local clone (copies the local SKILL.md) and piped from curl
# (downloads SKILL.md from the repo):
#
#   curl -fsSL https://raw.githubusercontent.com/sidhartha1s/clean-slate/main/install.sh | sh -s -- codex
set -eu

HARNESS="${1:-claude-code}"
SCOPE="${2:-}"
RAW_SKILL="https://raw.githubusercontent.com/sidhartha1s/clean-slate/main/SKILL.md"

case "$HARNESS" in
  claude-code) GLOBAL_DIR="$HOME/.claude/skills/clean-slate";   PROJECT_DIR=".claude/skills/clean-slate" ;;
  codex)       GLOBAL_DIR="$HOME/.codex/skills/clean-slate";    PROJECT_DIR=".agents/skills/clean-slate" ;;
  openclaw)    GLOBAL_DIR="$HOME/.openclaw/skills/clean-slate"; PROJECT_DIR=".openclaw/skills/clean-slate" ;;
  hermes)      GLOBAL_DIR="$HOME/.hermes/skills/clean-slate";   PROJECT_DIR="skills/clean-slate" ;;
  -h|--help)
    echo "usage: install.sh [claude-code|codex|openclaw|hermes] [--project]"; exit 0 ;;
  *)
    echo "clean-slate: unknown harness '$HARNESS' (claude-code|codex|openclaw|hermes)" >&2; exit 1 ;;
esac

if [ "$SCOPE" = "--project" ]; then DEST="$PROJECT_DIR"; else DEST="$GLOBAL_DIR"; fi

mkdir -p "$DEST"
if [ -f "./SKILL.md" ]; then
  cp "./SKILL.md" "$DEST/SKILL.md"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$RAW_SKILL" -o "$DEST/SKILL.md"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$DEST/SKILL.md" "$RAW_SKILL"
else
  echo "clean-slate: need a local SKILL.md, or curl/wget to download one" >&2; exit 1
fi

echo "clean-slate installed for $HARNESS -> $DEST/SKILL.md"
