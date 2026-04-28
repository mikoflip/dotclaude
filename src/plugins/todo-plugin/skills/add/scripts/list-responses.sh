#!/usr/bin/env bash
# list-responses.sh — extract assistant responses from a Claude Code session transcript
# Usage: list-responses.sh [-l] <session-id>
#   -l  print only the last response

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

if $LAST; then
  jq -rn '[inputs
    | select(.type == "assistant" and .message.role == "assistant")
    | (.message.content | if type == "string" then .
       else map(select(.type == "text") | .text) | join("") end)
    | select(length > 0)
  ] | last // empty' "$TRANSCRIPT"
else
  echo "Claude Code Session Responses"
  echo "Session ID: $SESSION_ID"
  echo ""
  jq -r '
    select(.type == "assistant" and .message.role == "assistant")
    | (.message.content | if type == "string" then .
       else map(select(.type == "text") | .text) | join("") end)
    | select(length > 0)
  ' "$TRANSCRIPT" | awk '{ printf "%3d. %s\n\n", NR, $0 }'
fi
