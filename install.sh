#!/usr/bin/env sh
# macos-tmux installer.
# 1. Symlinks tmux.conf into place.
# 2. Optionally injects an auto-attach snippet into your shell rc so every new
#    terminal is wrapped in tmux.

set -eu

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_SRC="$SRC_DIR/tmux.conf"

if [ ! -f "$CONF_SRC" ]; then
  echo "error: tmux.conf not found next to this script ($CONF_SRC)" >&2
  exit 1
fi

# ── 1. Place the config ─────────────────────────────────────────────────────
# Prefer XDG location; tmux 3.1+ reads ~/.config/tmux/tmux.conf.
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
CONF_DST="$CONF_DIR/tmux.conf"

mkdir -p "$CONF_DIR"
if [ -L "$CONF_DST" ]; then
  # Existing symlink: leave ours alone, but back up one pointing elsewhere.
  if [ "$(readlink "$CONF_DST")" = "$CONF_SRC" ]; then
    echo "Already linked: $CONF_DST"
  else
    backup="$CONF_DST.bak.$(date +%s)"
    echo "Backing up foreign symlink $CONF_DST -> $backup"
    mv "$CONF_DST" "$backup"
  fi
elif [ -e "$CONF_DST" ]; then
  # Existing regular file: back it up.
  backup="$CONF_DST.bak.$(date +%s)"
  echo "Backing up existing $CONF_DST -> $backup"
  mv "$CONF_DST" "$backup"
fi
ln -sf "$CONF_SRC" "$CONF_DST"
echo "Linked $CONF_DST -> $CONF_SRC"

# ── 2. Optional auto-attach wrapping ────────────────────────────────────────
MARKER="# >>> macos-tmux auto-attach >>>"
END_MARKER="# <<< macos-tmux auto-attach <<<"

SNIPPET="$MARKER
if command -v tmux >/dev/null 2>&1 && [ -z \"\${TMUX:-}\" ] && [ -n \"\${PS1:-}\" ]; then
  tmux attach -t main 2>/dev/null || tmux new -s main
fi
$END_MARKER"

inject() {
  rc="$1"
  if [ -f "$rc" ] && grep -qF "$MARKER" "$rc"; then
    echo "Already wrapped: $rc (skipping)"
    return
  fi
  printf '\n%s\n' "$SNIPPET" >> "$rc"
  echo "Wrapped: $rc"
}

# Wrap every new terminal automatically — no prompt. Pass --no-wrap to skip.
if [ "${1:-}" = "--no-wrap" ]; then
  echo "Skipped auto-attach (--no-wrap). Config installed at $CONF_DST."
  echo "Load it manually with: tmux"
else
  wrapped=0
  # Any existing rc gets wrapped.
  if [ -f "$HOME/.zshrc" ];  then inject "$HOME/.zshrc";  wrapped=1; fi
  if [ -f "$HOME/.bashrc" ]; then inject "$HOME/.bashrc"; wrapped=1; fi
  # If neither exists yet, create the one matching the login shell.
  if [ "$wrapped" -eq 0 ]; then
    case "${SHELL##*/}" in
      bash) inject "$HOME/.bashrc" ;;
      *)    inject "$HOME/.zshrc"  ;;
    esac
  fi
  echo "Done. Open a new terminal (or 'source' your rc) to start using it."
fi
