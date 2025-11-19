#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

echo "=================================================="
echo "📆 Hyper Factory – دورة تشغيل يومية موحّدة (Daily Ops)"
echo "ROOT : $ROOT"
echo "TIME : $NOW (UTC)"
echo "=================================================="

# 1) دورة مالك/مدير كاملة (تقارير + ملخصات)
if [ -x "$ROOT/hf_ops_master.sh" ]; then
  echo "🔹 [STEP 1] تشغيل hf_ops_master.sh ..."
  (cd "$ROOT" && ./hf_ops_master.sh)
else
  echo "[WARN] hf_ops_master.sh غير موجود أو غير قابل للتنفيذ."
fi

# 2) دورة التعلّم الكاملة
if [ -x "$ROOT/hf_run_learning_cycle.sh" ]; then
  echo "🔹 [STEP 2] تشغيل hf_run_learning_cycle.sh ..."
  (cd "$ROOT" && ./hf_run_learning_cycle.sh)
else
  echo "[WARN] hf_run_learning_cycle.sh غير موجود أو غير قابل للتنفيذ."
fi

# 3) تصدير AI Context Snapshot
if [ -x "$ROOT/hf_export_ai_context.sh" ]; then
  echo "🔹 [STEP 3] تشغيل hf_export_ai_context.sh ..."
  (cd "$ROOT" && ./hf_export_ai_context.sh)
else
  echo "[WARN] hf_export_ai_context.sh غير موجود أو غير قابل للتنفيذ."
fi

echo "=================================================="
echo "✅ دورة hf_run_daily_ops.sh اكتملت."
echo "يمكنك مراجعة:"
echo "  - reports/ai/OWNER_*_owner_report.md"
echo "  - reports/management/*_manager_daily_overview.*"
echo "  - reports/ai/*_ai_context_snapshot.md"
echo "  - ai/memory/lessons/*.json"
echo "=================================================="
