#!/usr/bin/env bash
# hf_log_last_run.sh
# يسجّل آخر دورة من basic_runs.log في ai/memory/messages.jsonl

set -euo pipefail

ROOT="/root/hyper-factory"
SCRIPT="$ROOT/tools/hf_log_last_run.py"

echo "📁 ROOT   : $ROOT"
echo "📄 SCRIPT : $SCRIPT"
echo "----------------------------------------"

cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 غير متوفر في PATH."
  exit 1
fi

if [[ ! -f "$SCRIPT" ]]; then
  echo "❌ ملف hf_log_last_run.py غير موجود: $SCRIPT"
  exit 1
fi

python3 "$SCRIPT"
