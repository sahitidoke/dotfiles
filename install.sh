#!/usr/bin/env bash
# Dotfiles install script: VS Code runs it automatically in every dev container.
# Safe to re-run: each step is skipped if its result already exists.
set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

# Docker creates named volumes owned by root; give them to this user.
for d in "$HOME/.claude" "$HOME/.cache/hive" "$HOME/.alignment-hive"; do
  sudo mkdir -p "$d"
  sudo chown -R "$(id -u):$(id -g)" "$d"
done

# Make ~/.local/bin (claude, hive) available in every terminal.
grep -qF '.local/bin' "$HOME/.bashrc" 2>/dev/null \
  || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

# 1. Claude Code (native installer, no Node needed)
if [ ! -x "$HOME/.local/bin/claude" ]; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# 2. hive binary. alignment-hive publishes no linux-arm64 build, so on
#    Apple Silicon we compile it once; the result lives in a volume and
#    survives rebuilds. Only runs once the hive plugin is installed.
PLUGINS="$HOME/.claude/plugins/installed_plugins.json"
if [ -f "$PLUGINS" ]; then
  PLUGIN_PATH=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["plugins"]["hive@alignment-hive"][0]["installPath"])' "$PLUGINS" 2>/dev/null || true)
  if [ -n "$PLUGIN_PATH" ] && [ -f "$PLUGIN_PATH/cli-version" ]; then
    VERSION=$(tr -d '[:space:]' < "$PLUGIN_PATH/cli-version")
    BIN="$HOME/.cache/hive/v$VERSION/hive"

    if [ ! -x "$BIN" ]; then
      case "$(uname -m)" in
        x86_64) TARGET=linux-x64 ;;
        *)      TARGET="" ;;
      esac
      mkdir -p "$(dirname "$BIN")"
      if [ -n "$TARGET" ] && curl -fsSL -o "$BIN" \
          "https://github.com/Crazytieguy/alignment-hive/releases/download/hive-cli-v$VERSION/hive-cli-$TARGET"; then
        chmod +x "$BIN"
      else
        rm -f "$BIN"
        echo "Building hive v$VERSION from source (no prebuilt binary for $(uname -m))..."
        command -v unzip >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq unzip; }
        command -v bun >/dev/null || curl -fsSL https://bun.sh/install | bash
        SRC=$(mktemp -d)
        git clone -q --depth 1 --branch "hive-cli-v$VERSION" \
          https://github.com/Crazytieguy/alignment-hive "$SRC" \
          || git clone -q --depth 1 https://github.com/Crazytieguy/alignment-hive "$SRC"
        (
          cd "$SRC"
          bun install
          bun run --filter '@alignment-hive/review-app' build
          bun build --compile --minify --no-compile-autoload-dotenv \
            packages/hive-cli/src/cli.ts --outfile "$BIN"
        )
        rm -rf "$SRC"
      fi
    fi

    mkdir -p "$HOME/.local/bin"
    ln -sf "$BIN" "$HOME/.local/bin/hive"
    echo "hive v$VERSION ready."
  fi
else
  echo "hive plugin not installed yet. Run once:"
  echo "  curl -fsSL https://alignment-hive.com/install.sh | bash"
  echo "If it fails at the binary download, run: bash ~/dotfiles/install.sh"
fi
[ -n "${REMOTE_CONTAINERS:-}" ] && bash "$(dirname "$0")/claude-container.sh"