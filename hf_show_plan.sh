#!/usr/bin/env bash
# hf_show_plan.sh - عرض خطة Hyper Factory (factory + agents)

set -euo pipefail

ROOT="/root/hyper-factory"
SCRIPT="$ROOT/tools/show_plan.py"

echo "📁 ROOT   : $ROOT"
echo "📄 SCRIPT : $SCRIPT"
echo "----------------------------------------"

if [[ ! -f "$SCRIPT" ]]; then
  echo "❌ ملف show_plan.py غير موجود: $SCRIPT"
  exit 1
fi

cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 غير متوفر في PATH."
  exit 1
fi

python3 "$SCRIPT"
