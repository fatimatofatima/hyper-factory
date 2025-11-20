#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

DB_PATH="$ROOT/data/factory/factory.db"
CLI_FACTORY="$ROOT/hf_factory_cli.sh"
DAILY_PY="$ROOT/tools/hf_factory_daily_report.py"

echo "📆 Hyper Factory – Daily Knowledge & Quality Review"
echo "==================================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

# 1) ضمان وجود قاعدة البيانات
if [ ! -f "$DB_PATH" ]; then
  echo "🧱 قاعدة بيانات المصنع غير موجودة – محاولة تشغيل init-db..."
  if [ -x "$CLI_FACTORY" ]; then
    "$CLI_FACTORY" init-db
  else
    echo "❌ hf_factory_cli.sh غير موجود أو غير قابل للتنفيذ."
    exit 1
  fi
fi

# 2) تشغيل محرك المراجعة اليومية + بناء مهام التدريب/الاختبارات
if [ -f "$DAILY_PY" ]; then
  python3 "$DAILY_PY" run || echo "⚠️ daily report انتهى بتحذير."
else
  echo "❌ tools/hf_factory_daily_report.py غير موجود."
  exit 1
fi

echo ""
echo "✅ Daily Review finished."
