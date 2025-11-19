#!/usr/bin/env bash
# agents/ingestor_basic.sh - تشغيل عامل ingestor_basic

set -euo pipefail

ROOT="/root/hyper-factory"
SCRIPT="$ROOT/agents/ingestor_basic.py"

echo "📁 ROOT   : $ROOT"
echo "📄 SCRIPT : $SCRIPT"
echo "----------------------------------------"

if [[ ! -f "$SCRIPT" ]]; then
  echo "❌ الملف غير موجود: $SCRIPT"
  exit 1
fi

cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 غير متوفر في النظام."
  exit 1
fi

python3 "$SCRIPT"
