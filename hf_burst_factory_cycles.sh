#!/usr/bin/env bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT" || { echo "❌ ROOT not found"; exit 1; }

ROUNDS="${1:-20}"   # عدد جولات البيرست، عدّله لو حابب (مثلاً 100 أو 500)

echo "🔥 Hyper Factory BURST MODE – ROUNDS = ${ROUNDS}"
echo "⚠️ لا يوجد أي sleep داخل هذا السكربت – حمولة كاملة على المعالج."

run_if_exists () {
  local s="$1"
  if [ -x "$ROOT/$s" ]; then
    echo "▶ RUN: $s"
    "$ROOT/$s" || echo "⚠️ WARN: $s انتهى بكود خطأ $?"
  else
    echo "⏭ SKIP: $s"
  fi
}

for i in $(seq 1 "$ROUNDS"); do
  echo "================ BURST ROUND $i / $ROUNDS ================"

  # خط الإنتاج الأساسي
  run_if_exists "run_basic_cycle.sh"
  run_if_exists "run_basic_with_memory.sh"
  run_if_exists "run_basic_with_report.sh"

  # دورة متقدمة: أنماط + جودة + معرفة
  run_if_exists "hf_run_advanced_cycle.sh"
  run_if_exists "hf_run_knowledge_spider.sh"
  run_if_exists "hf_run_patterns_engine.sh"
  run_if_exists "hf_run_quality_engine.sh"
  run_if_exists "hf_run_quality_worker.sh"

  # تدريب/تعلم/ذاكرة
  run_if_exists "hf_run_learning_cycle.sh"
  run_if_exists "hf_run_offline_learner.sh"
  run_if_exists "hf_run_apply_lessons.sh"
  run_if_exists "hf_run_export_lessons.sh"
  run_if_exists "hf_run_temporal_memory.sh"
  run_if_exists "hf_run_smart_worker.sh"

  # قيادة/إدارة
  run_if_exists "hf_ops_master.sh"
  run_if_exists "hf_run_manager_dashboard.sh"
done

echo "✅ BURST MODE انتهى – راجع التقارير والذاكرة لقياس عدد المهام الفعلي المنفذة."
