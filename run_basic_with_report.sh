#!/usr/bin/env bash
# run_basic_with_report.sh
# يشغّل دورة Hyper Factory الأساسية ثم يولّد تقرير

set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "🚀 تشغيل دورة Hyper Factory الأساسية..."
bash scripts/basic_pipeline/run_basic_cycle.sh

echo "📊 توليد تقرير الأداء..."
python3 scripts/basic_pipeline/reporter_basic.py

echo "✅ انتهى التشغيل + التقارير. راجع:"
echo "   - data/report/summary_basic.json"
echo "   - data/report/summary_basic.txt"
