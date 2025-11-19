#!/usr/bin/env bash
# hf_run_debug_expert.sh
# تشغيل عامل Debug Expert لتحليل basic_runs.log

set -euo pipefail

ROOT="/root/hyper-factory"
SCRIPT="$ROOT/tools/hf_debug_expert.py"

echo "📁 ROOT   : $ROOT"
echo "📄 SCRIPT : $SCRIPT"
echo "----------------------------------------"

cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 غير متوفر في PATH."
  exit 1
fi

if [[ ! -f "$SCRIPT" ]]; then
  echo "❌ ملف hf_debug_expert.py غير موجود: $SCRIPT"
  exit 1
fi

python3 "$SCRIPT"
