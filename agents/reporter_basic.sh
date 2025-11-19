#!/usr/bin/env bash
# agents/reporter_basic.sh - تشغيل reporter_basic

set -euo pipefail

ROOT="/root/hyper-factory"
SCRIPT="$ROOT/agents/reporter_basic.py"

echo "📁 ROOT   : $ROOT"
echo "📄 SCRIPT : $SCRIPT"
echo "----------------------------------------"

if [[ ! -f "$SCRIPT" ]]; then
  echo "❌ الملف غير موجود: $SCRIPT"
  exit 1
fi

cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 غير متوفر في PATH."
  exit 1
fi

python3 "$SCRIPT"
