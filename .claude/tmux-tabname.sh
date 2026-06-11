#!/usr/bin/env bash
# Names the current tmux window after the general work happening in this Claude
# session. Invoked async from the UserPromptSubmit hook; reads the hook JSON on
# stdin (.prompt + .transcript_path) and summarizes recent typed prompts via Haiku.
#
# The label is kept STICKY: Haiku is shown the current tab name and only changes
# it when the focus clearly shifts, so it doesn't flip-flop between synonyms on
# every prompt. A short per-pane cooldown further limits how often it re-runs.

[ -z "$TMUX" ] && exit 0

COOLDOWN=${CLAUDE_TABNAME_COOLDOWN:-60}
pane_id=$(printf '%s' "$TMUX_PANE" | tr -dc 'a-zA-Z0-9')
stamp="${TMPDIR:-/tmp}/claude-tabname-${pane_id}"
now=$(date +%s)
if [ -f "$stamp" ]; then
  last=$(cat "$stamp" 2>/dev/null)
  [ -n "$last" ] && [ $((now - last)) -lt "$COOLDOWN" ] && exit 0
fi

input=$(cat)
cur=$(printf '%s' "$input" | jq -r '.prompt // empty')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

# Recent typed user prompts give the overall theme; the current prompt adds recency.
hist=$(jq -r 'select(.type=="user" and .promptSource=="typed" and (.message.content|type=="string")) | .message.content' "$transcript" 2>/dev/null | tail -n 10)
ctx=$(printf '%s\n%s' "$hist" "$cur" | head -c 3000)
[ -z "$ctx" ] && exit 0

current=$(tmux display-message -p -t "$TMUX_PANE" '#W' 2>/dev/null)

name=$(printf 'CURRENT TAB LABEL: "%s"\n\nRECENT REQUESTS (oldest first):\n%s' "$current" "$ctx" \
  | claude -p --model haiku 'You label a tmux tab after the user'\''s current coding focus in one session. If the CURRENT TAB LABEL still reasonably describes the recent requests, reply with it EXACTLY, unchanged. Only if the focus has clearly moved to a different feature or area, reply with a new label: 2-4 lowercase words, a short noun phrase, max 22 chars, no vague words like "task"/"stuff"/"push"/"fix"/"unclear". Reply with only the label, no punctuation or quotes.' 2>/dev/null \
  | tr '[:upper:]' '[:lower:]' | tr -dc 'a-z \n' | tr -s ' ' | sed 's/^ *//;s/ *$//' | head -c 22)

printf '%s' "$now" > "$stamp"
[ -n "$name" ] && [ "$name" != "$current" ] && tmux rename-window -t "$TMUX_PANE" "$name"
