#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

RESULTS_CLI="$ROOT/hf_factory_results_cli.sh"
DASHBOARD="$ROOT/hf_factory_dashboard.sh"

echo "🤖 Hyper Factory – Improvement Smart Run"
echo "======================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

if [ ! -x "$RESULTS_CLI" ]; then
  echo "❌ hf_factory_results_cli.sh غير موجود أو غير قابل للتنفيذ."
  exit 1
fi

echo "🧮 خطوة 1: إعادة حساب أداء العمال من سجل task_assignments..."
./hf_factory_results_cli.sh recompute-agents
echo ""
echo "📊 خطوة 2: عرض ترتيب العمال حسب الأداء:"
./hf_factory_results_cli.sh show-agents
echo ""

echo "📈 خطوة 3: (اختياري) عرض لوحة تحكم المصنع:"
if [ -x "$DASHBOARD" ]; then
  ./hf_factory_dashboard.sh
else
  echo "  ⚠️ hf_factory_dashboard.sh غير موجود أو غير قابل للتنفيذ."
fi

echo ""
echo "✅ Improvement Smart Run اكتمل."
