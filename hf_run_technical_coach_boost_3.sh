#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

LOG_DIR="$ROOT/logs/factory"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/agent_technical_coach.log"

DESC="$*"
TASK_ID="${TASK_ID:-unknown}"
TS="$(date -Iseconds)"

echo "========================================" >> "$LOG_FILE"
echo "[$TS] agent=technical_coach TASK_ID=$TASK_ID" >> "$LOG_FILE"
echo "DESC: $DESC" >> "$LOG_FILE"

# محاكاة عمل العامل
sleep 2

echo "RESULT: success" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

echo "✅ technical_coach: تم تنفيذ المهمة بنجاح"
echo "   TASK_ID=$TASK_ID"
