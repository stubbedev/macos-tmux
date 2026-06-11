#!/usr/bin/env sh
# macos-tmux uninstaller. Reverses install.sh:
#   - removes the tmux.conf symlink (only if it points at this repo)
#   - strips the guarded auto-attach block from ~/.zshrc and ~/.bashrc
# Leaves any user backups (*.bak.*) untouched.

set -eu

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_SRC="$SRC_DIR/tmux.conf"

MARKER="# >>> macos-tmux auto-attach >>>"
END_MARKER="# <<< macos-tmux auto-attach <<<"

# ── 1. Remove the config symlink ────────────────────────────────────────────
CONF_DST="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
if [ -L "$CONF_DST" ]; then
  target="$(readlink "$CONF_DST")"
  if [ "$target" = "$CONF_SRC" ]; then
    rm "$CONF_DST"
    echo "Removed symlink $CONF_DST"
  else
    echo "Left $CONF_DST alone (points elsewhere: $target)"
  fi
elif [ -e "$CONF_DST" ]; then
  echo "Left $CONF_DST alone (not a symlink — not ours to delete)"
else
  echo "No symlink at $CONF_DST"
fi

# Also clean the legacy ~/.tmux.conf location if it links here.
LEGACY="$HOME/.tmux.conf"
if [ -L "$LEGACY" ] && [ "$(readlink "$LEGACY")" = "$CONF_SRC" ]; then
  rm "$LEGACY"
  echo "Removed symlink $LEGACY"
fi

# ── 2. Strip the auto-attach block from rc files ────────────────────────────
strip() {
  rc="$1"
  [ -f "$rc" ] || return 0
  grep -qF "$MARKER" "$rc" || { echo "Not wrapped: $rc"; return 0; }
  tmp="$rc.macos-tmux.tmp"
  # Delete the marker block plus one immediately-preceding blank line (install
  # prepends a blank), leaving the rest of the file untouched.
  awk -v s="$MARKER" -v e="$END_MARKER" '
    $0 == s { if (blank) blank=0; else if (held) print held; held=""; skip=1; next }
    skip { if ($0 == e) skip=0; next }
    { if (held) print held; held=$0; blank=($0=="") }
    END { if (held && !skip) print held }
  ' "$rc" > "$tmp"
  # Write back in place (cat, not mv) to preserve the rc file's permissions.
  cat "$tmp" > "$rc"
  rm -f "$tmp"
  echo "Unwrapped: $rc"
}

strip "$HOME/.zshrc"
strip "$HOME/.bashrc"

echo "Done. Existing tmux sessions keep running until killed (tmux kill-server)."
