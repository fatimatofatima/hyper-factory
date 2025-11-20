#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

LOG_DIR="$ROOT/logs/factory"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/agent_debug_expert.log"

DESC="$*"
TASK_ID="${TASK_ID:-unknown}"
TS="$(date -Iseconds)"

echo "========================================" >> "$LOG_FILE"
echo "[$TS] agent=debug_expert TASK_ID=$TASK_ID" >> "$LOG_FILE"
echo "DESC: $DESC" >> "$LOG_FILE"
echo "NOTE: تنفيذ افتراضي (stub) – لم يتم ربط باك إند حقيقي بعد." >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

echo "✅ debug_expert: تم تسجيل المهمة في $LOG_FILE"
echo "   TASK_ID=$TASK_ID"
echo "   DESC=$DESC"
