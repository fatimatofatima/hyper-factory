#!/usr/bin/env bash
# hf_run_manager_dashboard.sh
# تشغيل Manager Dashboard لتجميع تقرير مدير المصنع من مخرجات اليوم

set -euo pipefail

ROOT="/root/hyper-factory"
SCRIPT="$ROOT/tools/hf_manager_dashboard.py"

echo "📁 ROOT   : $ROOT"
echo "📄 SCRIPT : $SCRIPT"
echo "----------------------------------------"

cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 غير متوفر في PATH."
  exit 1
fi

if [[ ! -f "$SCRIPT" ]]; then
  echo "❌ ملف hf_manager_dashboard.py غير موجود: $SCRIPT"
  exit 1
fi

python3 "$SCRIPT"

echo "----------------------------------------"
if ls reports/management/*_manager_daily_overview.txt >/dev/null 2>&1; then
  latest_txt=$(ls reports/management/*_manager_daily_overview.txt | sort | tail -n1)
  echo "📄 أحدث تقرير مدير المصنع:"
  echo "   $latest_txt"
  echo
  head -n 80 "$latest_txt"
else
  echo "ℹ️ لم يتم العثور على أي تقارير في reports/management/."
fi
