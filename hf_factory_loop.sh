#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

DB_PATH="$ROOT/data/factory/factory.db"
CLI_FACTORY="$ROOT/hf_factory_cli.sh"
LOOP_SLEEP="${HF_LOOP_SLEEP:-120}"   # ثواني بين الدورات (افتراضي 120 ثانية)
MAX_ASSIGN_PER_CYCLE="${HF_MAX_ASSIGN:-3}"  # أقصى عدد مهام يتم إسنادها في كل دورة

echo "🔁 Hyper Factory – Continuous Factory Loop"
echo "========================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo "📄 DB  : $DB_PATH"
echo "🕒 LOOP_SLEEP: ${LOOP_SLEEP}s  |  MAX_ASSIGN_PER_CYCLE: ${MAX_ASSIGN_PER_CYCLE}"
echo ""

if [ ! -x "$CLI_FACTORY" ]; then
  echo "❌ hf_factory_cli.sh غير موجود أو غير قابل للتنفيذ."
  exit 1
fi

# تأكد أن قاعدة البيانات مهيّأة
echo "🧱 تهيئة المصنع (init-db) إن لزم..."
"$CLI_FACTORY" init-db || echo "⚠️ init-db فشل بشكل غير قاتل."

cycle=0

while true; do
  cycle=$((cycle+1))
  echo ""
  echo "===== 🔄 دورة المصنع رقم $cycle @ $(date) ====="

  # 1) تأكد من وجود DB
  if [ ! -f "$DB_PATH" ]; then
    echo "⚠️ قاعدة البيانات غير موجودة، إعادة init-db..."
    "$CLI_FACTORY" init-db || echo "⚠️ init-db فشل."
  fi

  # 2) قراءة حجم الطابور الحالي
  if [ -f "$DB_PATH" ]; then
    queued_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM tasks WHERE status='queued';" || echo "0")"
  else
    queued_count="0"
  fi
  echo "📥 حجم الطابور الحالي (queued): $queued_count"

  # 3) حقن مهام معرفة/جودة/تدريب عند انخفاض الطابور
  if [ "$queued_count" -lt 3 ]; then
    echo "🧠 الطابور منخفض – حقن مهام معرفة/جودة/تدريب..."
    # مهام معرفة (Spiders)
    "$CLI_FACTORY" new "جمع معرفة جديدة من الكود واللوجات والمستندات" normal || true
    "$CLI_FACTORY" new "تحديث قاعدة المعرفة وربط الأنماط الحالية بالتقارير" normal || true

    # مهام جودة/أنماط
    "$CLI_FACTORY" new "تحليل جودة مخرجات المصنع واكتشاف الأخطاء المتكررة" low || true
    "$CLI_FACTORY" new "تحديث أنماط Patterns Engine بناءً على آخر التقارير" low || true

    # مهام تدريب (Coaching) – للمستخدم/العامل الافتراضي angel أو غيره لاحقًا
    "$CLI_FACTORY" new "تصميم تمرين عملي لتحسين مهارات التصحيح (debug) للمستخدمين" normal || true
    "$CLI_FACTORY" new "بناء خطة تدريبية قصيرة لتحسين فهم البنية المعمارية للمشروع" normal || true
  else
    echo "ℹ️ الطابور كافي – لا حاجة لحقن مهام إضافية في هذه الدورة."
  fi

  # 4) إسناد عدد من المهام (حسب MAX_ASSIGN_PER_CYCLE)
  echo "🎯 محاولة إسناد حتى $MAX_ASSIGN_PER_CYCLE مهمة في هذه الدورة..."
  i=1
  while [ "$i" -le "$MAX_ASSIGN_PER_CYCLE" ]; do
    echo "  ➜ assign-next #$i"
    # هذا يستدعي أوركستريتور Python ويطبع أمر التنفيذ المقترح (hf_run_*...)
    "$CLI_FACTORY" assign-next || {
      echo "  ℹ️ ربما لا توجد مهام قابلة للإسناد حالياً."
      break
    }
    i=$((i+1))
  done

  echo "✅ نهاية دورة المصنع رقم $cycle – sleep ${LOOP_SLEEP}s..."
  sleep "$LOOP_SLEEP"
done
