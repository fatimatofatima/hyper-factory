#!/usr/bin/env bash
set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

LOG_DIR="$ROOT/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hf_run_apply_lessons.log"

ts="$(date -Is)"
{
  echo "[$ts] === hf_run_apply_lessons – start ==="
  echo "ROOT: $ROOT"
} >> "$LOG_FILE"

if ! command -v python3 >/dev/null 2>&1; then
  echo "[$ts] ERROR: python3 غير موجود في PATH." >> "$LOG_FILE"
  exit 1
fi

python3 "$ROOT/tools/hf_apply_lessons.py" >> "$LOG_FILE" 2>&1 || {
  echo "[$ts] ERROR: فشل تنفيذ hf_apply_lessons.py" >> "$LOG_FILE"
  exit 0
}

echo "[$ts] === hf_run_apply_lessons – done ===" >> "$LOG_FILE"
