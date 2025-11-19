#!/usr/bin/env bash
# hf_run_system_architect.sh
# تشغيل System Architect Worker على design/intents/*.md

set -euo pipefail

ROOT="/root/hyper-factory"
SCRIPT="$ROOT/tools/hf_system_architect.py"

echo "📁 ROOT   : $ROOT"
echo "📄 SCRIPT : $SCRIPT"
echo "----------------------------------------"

cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 غير متوفر في PATH."
  exit 1
fi

if [[ ! -f "$SCRIPT" ]]; then
  echo "❌ ملف hf_system_architect.py غير موجود: $SCRIPT"
  exit 1
fi

python3 "$SCRIPT"
