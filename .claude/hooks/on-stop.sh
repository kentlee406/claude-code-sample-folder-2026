#!/usr/bin/env bash
PROJECT="${CLAUDE_PROJECT_NAME:-unknown-project}"
LOG_FILE="$(dirname "$0")/stop.log"

echo "$(date '+%H:%M:%S')  Claude 回應完成 — ${PROJECT}" >> "$LOG_FILE"
