#!/usr/bin/env bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT" || { echo "❌ ROOT not found"; exit 1; }

echo "=== [1] Backup agents.yaml القديم (إن وُجد) ==="
if [ -f "config/agents.yaml" ]; then
  TS="$(date +%Y%m%d_%H%M%S)"
  mkdir -p config/backup
  cp config/agents.yaml "config/backup/agents.yaml.${TS}"
  echo "✅ backup → config/backup/agents.yaml.${TS}"
else
  echo "ℹ️ لا يوجد config/agents.yaml قديم."
fi

echo "=== [2] تأكيد وجود التكوين الجديد ==="
if [ ! -f "config/agents.yaml" ]; then
  echo "❌ config/agents.yaml غير موجود. أنشئه أولاً."
  exit 1
fi

echo "=== [3] حذف ملف \$DB_PATH الوهمي إن وُجد ==="
if [ -f "\$DB_PATH" ]; then
  ls -l "\$DB_PATH"
  rm -f "\$DB_PATH"
  echo "✅ تم حذف الملف الوهمي \$DB_PATH"
else
  echo "ℹ️ لا يوجد ملف باسم \$DB_PATH في الجذر."
fi

echo "=== [4] توحيد مسار قاعدة المعرفة (knowledge.db) ==="
OFFICIAL_DB_DIR="$ROOT/data/knowledge"
OFFICIAL_DB_PATH="$OFFICIAL_DB_DIR/knowledge.db"
mkdir -p "$OFFICIAL_DB_DIR"

if [ -f "$OFFICIAL_DB_PATH" ]; then
  echo "✅ DB رسمية موجودة بالفعل: $OFFICIAL_DB_PATH"
else
  echo "ℹ️ لا توجد DB رسمية في $OFFICIAL_DB_PATH – البحث عن أي knowledge.db أخرى..."
  CANDIDATE="$(find "$ROOT" -maxdepth 6 -type f -name 'knowledge.db' 2>/dev/null | head -n1 || true)"
  if [ -n "$CANDIDATE" ]; then
    echo "✅ تم العثور على DB موجودة: $CANDIDATE"
    ln -s "$CANDIDATE" "$OFFICIAL_DB_PATH"
    echo "✅ تم عمل symlink → $OFFICIAL_DB_PATH → $CANDIDATE"
  else
    echo "⚠️ لم يتم العثور على أي knowledge.db – سيستمر النظام، لكن بعض الفحوص قد تظهر فارغة."
  fi
fi

echo "=== [5] تشغيل Bootstrap سريع للعمال بدون أي Sleep ==="

run_if_exists () {
  local s="$1"
  if [ -x "$ROOT/$s" ]; then
    echo "▶ RUN: $s"
    "$ROOT/$s" || echo "⚠️ WARN: $s انتهى بكود خطأ $?"
  else
    echo "⏭ SKIP (غير موجود أو غير تنفيذي): $s"
  fi
}

# خط الإنتاج الأساسي
run_if_exists "run_basic_cycle.sh"
run_if_exists "run_basic_with_memory.sh"
run_if_exists "run_basic_with_report.sh"

# فحوص وتكامل المعرفة/الجودة/الأنماط
run_if_exists "hf_run_full_checks.sh"
run_if_exists "hf_run_db_health.sh"
run_if_exists "hf_run_schema_review.sh"
run_if_exists "hf_run_knowledge_spider.sh"
run_if_exists "hf_run_knowledge_linking.sh"
run_if_exists "hf_run_patterns_engine.sh"
run_if_exists "hf_run_quality_engine.sh"
run_if_exists "hf_run_quality_worker.sh"

# تدريب/تعلم
run_if_exists "hf_run_learning_cycle.sh"
run_if_exists "hf_run_apply_lessons.sh"
run_if_exists "hf_run_export_lessons.sh"
run_if_exists "hf_run_offline_learner.sh"

# عمال متقدمة
run_if_exists "hf_run_enhanced_debug_expert.sh"
run_if_exists "hf_run_debug_expert.sh"
run_if_exists "hf_run_system_architect.sh"
run_if_exists "hf_run_technical_coach.sh"
run_if_exists "hf_run_temporal_memory.sh"
run_if_exists "hf_run_smart_worker.sh"

# إدارة
run_if_exists "hf_ops_master.sh"
run_if_exists "hf_run_manager_dashboard.sh"
run_if_exists "hf_master_dashboard.sh"
run_if_exists "hf_quick_dashboard.sh"
run_if_exists "hf_db_architect_brain.sh"

echo "=== [6] فحص التكوين/العمال بعد البوتستراب ==="
run_if_exists "hf_find_all_agents.sh"
run_if_exists "hf_comprehensive_audit.sh"
run_if_exists "hf_live_dashboard.sh"

echo "✅ Bootstrap Hyper Factory انتهى بدون أي Sleep مصطنع."
