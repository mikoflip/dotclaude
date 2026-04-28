#!/usr/bin/env bash
# hooks/status-line.sh — Claude Code status line
# Displays context window usage, 5-hour rate limit, model, and session ID.
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id')
model=$(echo "$input"      | jq -r '.model.display_name')
ctx=$(echo "$input"        | jq -r '.context_window.used_percentage')
five_h=$(echo "$input"     | jq -r '.rate_limits.five_hour.used_percentage // "N/A"')
echo "Used Context Window: ${ctx}% | 5h Usage: ${five_h}% | Model: ${model}"$'\n'"Session ID: ${session_id}"
