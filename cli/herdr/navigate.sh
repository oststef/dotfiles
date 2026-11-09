#!/bin/sh
# vim-tmux-navigator for herdr: nvim gets the key itself and calls back into
# herdr at its window edge (see nvim's vim-tmux-navigator.lua).
dir=$1 key=$2
pane=$HERDR_ACTIVE_PANE_ID
if herdr pane process-info --pane "$pane" | grep -qE '"name":"(n?vim|view)"'; then
  herdr pane send-keys "$pane" "$key"
else
  herdr pane focus --pane "$pane" --direction "$dir"
fi
