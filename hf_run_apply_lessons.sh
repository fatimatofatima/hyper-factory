#!/usr/bin/env bash
# hf_run_apply_lessons.sh
# تشغيل عامل Apply Lessons (بدون أي تعديل تلقائي على config)

set -euo pipefail

ROOT="/root/hyper-factory"
SCRIPT="$ROOT/tools/hf_apply_lessons.py"

echo "📁 ROOT   : $ROOT"
echo "📄 SCRIPT : $SCRIPT"
echo "----------------------------------------"

cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 غير متوفر في PATH."
  exit 1
fi

if [[ ! -f "$SCRIPT" ]]; then
  echo "❌ ملف hf_apply_lessons.py غير موجود: $SCRIPT"
  exit 1
fi

python3 "$SCRIPT"
