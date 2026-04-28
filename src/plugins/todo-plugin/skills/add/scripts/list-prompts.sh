#!/usr/bin/env bash
# list-prompts.sh — extract user prompts from a Claude Code session transcript
# Usage: list-prompts.sh [-l] <session-id>
#   -l  print only the last prompt

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed." >&2; exit 1; }

LAST=false
if [[ "$1" == "-l" ]]; then
  LAST=true
  shift
fi

SESSION_ID="$1"
TRANSCRIPT=$(find ~/.claude/projects -name "${SESSION_ID}.jsonl" 2>/dev/null | head -1)

if [[ -z "$TRANSCRIPT" ]]; then
  echo "Session not found: $SESSION_ID" >&2
  exit 1
fi

PROMPTS=$(jq -r '
  select(.type == "user" and .message.role == "user")
  | (.message.content | if type == "string" then .
     else map(select(.type == "text") | .text) | join("") end)
  | select(length > 0)
' "$TRANSCRIPT")

if $LAST; then
  echo "$PROMPTS" | tail -1
else
  echo "Claude Code Session Prompts"
  echo "Session ID: $SESSION_ID"
  echo ""
  echo "$PROMPTS" | awk '{ printf "%3d. %s\n\n", NR, $0 }'
fi
