#!/usr/bin/env bash
# VS Code runs this in every dev container (dotfiles.installCommand).
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

# /research slash command
mkdir -p "$HOME/.claude/commands"
ln -sf "$DIR/research.md" "$HOME/.claude/commands/research.md"

# Container-only setup: Claude Code, hive binary, jq for debrief
if [ -n "${REMOTE_CONTAINERS:-}" ] || [ -f /.dockerenv ]; then
  bash "$DIR/claude-container.sh"
  command -v jq >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq jq; }
fi
