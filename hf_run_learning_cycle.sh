#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo "🏭 Hyper Factory – دورة تعلّم كاملة (Learning Cycle)"
echo "ROOT: $ROOT"
echo "=================================================="

# 1) تشغيل المصنع مع الذاكرة
if [ -x "$ROOT/run_basic_with_memory.sh" ]; then
  echo "🔹 [STEP 1] تشغيل run_basic_with_memory.sh ..."
  (cd "$ROOT" && ./run_basic_with_memory.sh)
else
  echo "[WARN] run_basic_with_memory.sh غير موجود أو غير قابل للتنفيذ."
fi

# 2) تحديث لوحة الإدارة بعد التشغيل
if [ -x "$ROOT/hf_run_manager_dashboard.sh" ]; then
  echo "🔹 [STEP 2] تشغيل hf_run_manager_dashboard.sh (قبل الدروس) ..."
  (cd "$ROOT" && ./hf_run_manager_dashboard.sh)
else
  echo "[WARN] hf_run_manager_dashboard.sh غير موجود أو غير قابل للتنفيذ."
fi

# 3) تصدير الدروس من knowledge.db → ai/memory/lessons/*.json
if [ -x "$ROOT/hf_run_export_lessons.sh" ]; then
  echo "🔹 [STEP 3] تشغيل hf_run_export_lessons.sh ..."
  (cd "$ROOT" && ./hf_run_export_lessons.sh)
else
  echo "[WARN] hf_run_export_lessons.sh غير موجود أو غير قابل للتنفيذ."
fi

# 4) محاولة تطبيق الدروس على config (إن كانت الدروس معرّفة)
if [ -x "$ROOT/hf_run_apply_lessons.sh" ]; then
  echo "🔹 [STEP 4] تشغيل hf_run_apply_lessons.sh ..."
  (cd "$ROOT" && ./hf_run_apply_lessons.sh || echo '[WARN] hf_run_apply_lessons.sh انتهى مع تحذير/خطأ، راجع اللوج.') 
else
  echo "[WARN] hf_run_apply_lessons.sh غير موجود أو غير قابل للتنفيذ."
fi

# 5) تحديث لوحة الإدارة بعد تطبيق الدروس
if [ -x "$ROOT/hf_run_manager_dashboard.sh" ]; then
  echo "🔹 [STEP 5] تشغيل hf_run_manager_dashboard.sh (بعد الدروس) ..."
  (cd "$ROOT" && ./hf_run_manager_dashboard.sh)
fi

echo "=================================================="
echo "✅ دورة التعلّم مكتملة."
echo "📄 آخر تقارير Manager في: reports/management/*_manager_daily_overview.*"
echo "📁 دروس مصدَّرة في: ai/memory/lessons/"
echo "=================================================="
