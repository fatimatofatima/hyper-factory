#!/usr/bin/env bash
# Hyper Factory – Fix Manager Report Phase Section
# الاستخدام:
#   ./hf_fix_manager_phase_report.sh
#   ./hf_fix_manager_phase_report.sh /path/to/hyper-factory

set -u
set -o pipefail

ROOT="${1:-/root/hyper-factory}"
DB="$ROOT/data/knowledge/knowledge.db"

echo "ROOT: $ROOT"
echo "DB  : $DB"
echo

# 1) تحقق من المتطلبات
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "❌ sqlite3 غير موجود في النظام. الرجاء تثبيته أولاً."
  exit 1
fi

if [ ! -f "$DB" ]; then
  echo "❌ ملف قاعدة المعرفة غير موجود: $DB"
  exit 1
fi

# 2) قراءة الـ Phase النشطة من DB
line="$(sqlite3 "$DB" -separator '|' \
  "SELECT item_key, IFNULL(title,''), meta_json
   FROM knowledge_items
   WHERE item_type='curriculum_phase'
     AND meta_json LIKE '%\"is_current\": true%'
   LIMIT 1;")"

if [ -z "$line" ]; then
  echo "⚠️ لا توجد مرحلة current/active في DB، لن يتم تعديل التقارير."
  exit 0
fi

IFS='|' read -r CURR_KEY CURR_TITLE CURR_META <<<"$line"

echo "Current phase (from DB):"
echo "  key  : $CURR_KEY"
echo "  title: $CURR_TITLE"
echo

# 3) تحديد أحدث تقرير Manager TXT
LATEST_TXT="$(ls -1 "$ROOT"/reports/management/*_manager_daily_overview.txt 2>/dev/null | sort | tail -n 1 || true)"

if [ -z "${LATEST_TXT:-}" ]; then
  echo "⚠️ لا يوجد أي تقرير Manager TXT لتحديثه."
  exit 0
fi

echo "Latest Manager report: $LATEST_TXT"
echo

TMP="${LATEST_TXT}.tmp.$$"

# 4) إضافة بلوك override في آخر التقرير
{
  cat "$LATEST_TXT"
  echo
  echo "=================================================="
  echo "Phase State – Fixed Override (from knowledge.db)"
  echo "=================================================="
  echo "- Active curriculum phase key   : $CURR_KEY"
  echo "- Active curriculum phase title : $CURR_TITLE"
  echo "- Note: هذه الكتلة تُعد المرجع الأحدث لحالة المناهج،"
  echo "        وتتجاوز السطر العام الذي يقول:"
  echo "        'لا توجد مرحلة معلّمة كـ current/active حتى الآن.' إن وُجد أعلاه."
} >"$TMP"

mv "$TMP" "$LATEST_TXT"

echo "✅ تم تحديث التقرير وإضافة ملخص Phase في آخر الملف."
