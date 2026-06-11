# macos-tmux

An invisible tmux config. Drop it in front of any terminal to get persistent,
near-infinite scrollback without lag — same colors, normal mouse scroll and
copy, and no visible sign you're inside tmux.

## Install

```sh
ln -sf "$PWD/tmux.conf" ~/.tmux.conf   # or ~/.config/tmux/tmux.conf
```

Or load it ad hoc:

```sh
tmux -f /path/to/tmux.conf
```

## Auto-attach in every shell

To make it truly invisible, start (or attach to) a session whenever you open a
terminal. Add to `~/.zshrc`:

```sh
if [ -z "$TMUX" ] && [ -n "$PS1" ]; then
  tmux attach -t main 2>/dev/null || tmux new -s main
fi
```

## What it does

- **Scrollback** — `history-limit 1000000`. Stored in RAM per pane, so it's
  "infinite" in practice; cost is memory (a few hundred MB for a heavy pane),
  paid lazily. No lag in normal use.
- **Colors** — advertises `tmux-256color` and passes 24-bit truecolor straight
  through, so everything renders exactly as it would bare.
- **Mouse** — wheel scrolls into history and drops back to the prompt at the
  bottom; drag-select copies to the system clipboard via OSC52 (works over SSH).
  Hold **Shift** while dragging to use the terminal's own native selection.
- **Invisible** — no status bar, forwards the real window title, no bell/activity
  noise.

## Notes

- "Infinite" scrollback is capped at 1,000,000 lines — raise/lower
  `history-limit` to trade memory for depth.
- Clipboard relies on your terminal supporting OSC52 (iTerm2, kitty, Terminal.app,
  WezTerm, Ghostty, Alacritty, most modern emulators do).
