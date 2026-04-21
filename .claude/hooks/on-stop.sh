#!/usr/bin/env bash
PROJECT="${CLAUDE_PROJECT_NAME:-unknown-project}"
TIMESTAMP="$(date '+%H:%M:%S')"
LOG_FILE="$(dirname "$0")/stop.log"

# 1. 寫入 log 檔（可用 tail -f 觀察）
echo "${TIMESTAMP}  Claude 回應完成 — ${PROJECT}" >> "$LOG_FILE"

# 2. macOS 系統通知（VS Code 擴充套件模式下可見）
osascript -e "display notification \"Claude 回應完成\" with title \"Claude Code\" subtitle \"${PROJECT}\""
