#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

DB_PATH="$ROOT/data/factory/factory.db"
CLI_FACTORY="$ROOT/hf_factory_cli.sh"
ORCH_PY="$ROOT/tools/hf_factory_orchestrator.py"

# يمكن تغييرهم من المتغيّرات البيئية
INTERVAL="${HF_LOOP_INTERVAL:-60}"        # عدد الثواني بين كل دورة
MAX_ASSIGN_PER_LOOP="${HF_LOOP_MAX_ASSIGN:-5}"  # أقصى عدد مهام يوزّعها المدير في كل دورة

echo "🏭 Hyper Factory – Manager Continuous Loop"
echo "=========================================="
echo "⏰ $(date)"
echo "📍 ROOT : $ROOT"
echo "📄 DB   : $DB_PATH"
echo "⏱  Interval (sec): $INTERVAL"
echo "🔁 Max assign/loop: $MAX_ASSIGN_PER_LOOP"
echo ""

if [ ! -x "$CLI_FACTORY" ]; then
  echo "❌ hf_factory_cli.sh غير موجود أو غير قابل للتنفيذ."
  exit 1
fi

if [ ! -x "$ORCH_PY" ]; then
  echo "❌ tools/hf_factory_orchestrator.py غير موجود أو غير قابل للتنفيذ."
  exit 1
fi

# ضمان وجود قاعدة البيانات
if [ ! -f "$DB_PATH" ]; then
  echo "🧱 factory.db غير موجود – تشغيل init-db من المدير..."
  "$CLI_FACTORY" init-db
fi

# دالة: حقن مهام ذاتية (معرفة / جودة / تدريب) عندما يكون المصنع شبه فاضي
ensure_auto_tasks() {
  local now
  now="$(date --iso-8601=seconds)"

  # لو مافيش أي مهام غير منتهية، نضخ مهام ذاتية
  local active_cnt
  active_cnt="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM tasks WHERE status IN ('queued','assigned','running');")"
  if [ -z "$active_cnt" ]; then active_cnt=0; fi

  if [ "$active_cnt" -gt 0 ]; then
    return
  fi

  echo "🧠 [auto_manager] لا توجد مهام فعّالة – إنشاء دورة معرفة/جودة/تدريب ذاتية..."

  # 1) مهمة معرفة مستمرة (Knowledge Spider Family)
  local desc_knowledge="دورة معرفة مستمرة: جمع وتحديث المعرفة من Hyper Factory + SmartFriend + FFactory."
  sqlite3 "$DB_PATH" "
    INSERT INTO tasks (created_at, source, description, task_type, priority, status)
    VALUES ('$now', 'auto_manager', '$desc_knowledge', 'knowledge', 'normal', 'queued');
  "

  # 2) مهمة جودة واختبارات مستمرة (Quality / Debug Family)
  local desc_quality="فحص جودة مستمر: تحليل النتائج، تشغيل اختبارات، واستخراج Patterns للأخطاء لتحسين الأنظمة."
  sqlite3 "$DB_PATH" "
    INSERT INTO tasks (created_at, source, description, task_type, priority, status)
    VALUES ('$now', 'auto_manager', '$desc_quality', 'debug', 'normal', 'queued');
  "

  # 3) مهمة تدريب وخبرات للمستخدمين/العمّال (Coaching Family)
  local desc_training="تحديث مهارات وتدريب: بناء دورات واختبارات ذاتية بناءً على المدخلات والمخرجات الحالية."
  sqlite3 "$DB_PATH" "
    INSERT INTO tasks (created_at, source, description, task_type, priority, status)
    VALUES ('$now', 'auto_manager', '$desc_training', 'coaching', 'normal', 'queued');
  "

  echo "✅ تم حقن مهام auto_manager (معرفة + جودة + تدريب)."
}

# دالة: توزيع عدد محدد من المهام في كل دورة
assign_some_tasks() {
  local i=1
  while [ "$i" -le "$MAX_ASSIGN_PER_LOOP" ]; do
    local queued
    queued="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM tasks WHERE status='queued';")"
    if [ -z "$queued" ]; then queued=0; fi

    if [ "$queued" -eq 0 ]; then
      # لا توجد مهام في الطابور
      break
    fi

    echo "🎯 [manager] توزيع مهمة من الطابور (queued=$queued)..."
    python3 "$ORCH_PY" assign-next || echo "⚠️ فشل assign-next في هذه الدورة."
    i=$((i+1))
  done
}

echo "🚀 بدء Loop مدير المصنع (اضغط Ctrl+C للإيقاف اليدوي)."
echo ""

while true; do
  # تأمين أن الـ DB موجودة
  if [ ! -f "$DB_PATH" ]; then
    echo "⚠️ factory.db مفقود داخل الـ Loop – إعادة init-db..."
    "$CLI_FACTORY" init-db
  fi

  # 1) حقن مهام معرفة/جودة/تدريب ذاتية عند الحاجة
  ensure_auto_tasks

  # 2) توزيع مجموعة مهام من الطابور على العائلات (سبايدر/كوتش/محلل/دكتور...)
  assign_some_tasks

  # 3) Sleep قبل الدورة التالية – تشغيل مستمر لكن بهدوء
  echo "⏸  Sleep $INTERVAL ثانية قبل الدورة التالية..."
  sleep "$INTERVAL"
done
