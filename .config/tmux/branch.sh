#!/bin/sh
# Print the git branch for the directory in $1, falling back to its basename.
#
# Replaces an inline `#(cd ... && git ... || echo ...)` in window-status-format.
# That compound command forced tmux to spawn a wrapping `sh -c`; when tmux tore
# it down on the next refresh the git/echo children were orphaned as zombies.
# This runs per window every refresh, so it stays a single fast process with no
# pipe: tmux owns it directly and reaps it. `git -C` avoids a `cd` subshell.
p="$1"
b=$(git -C "$p" rev-parse --abbrev-ref HEAD 2>/dev/null) && { printf '%s' "$b"; exit 0; }
printf '%s' "${p##*/}"
