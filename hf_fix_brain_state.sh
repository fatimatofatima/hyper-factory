#!/usr/bin/env bash
# Hyper Factory – Brain State Fix
# الاستخدام:
#   ./hf_fix_brain_state.sh                      # ROOT=/root/hyper-factory, PHASE_KEY=phase_scale_usage
#   ./hf_fix_brain_state.sh /path/to/hf phase_stable_reference

set -u
set -o pipefail

ROOT="${1:-/root/hyper-factory}"
PHASE_KEY="${2:-phase_scale_usage}"
DB="$ROOT/data/knowledge/knowledge.db"

echo "ROOT      : $ROOT"
echo "PHASE_KEY : $PHASE_KEY"
echo "DB        : $DB"
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

# 2) أخذ نسخة احتياطية من قاعدة المعرفة
TS="$(date +%Y%m%d_%H%M%S)"
BACKUP="$ROOT/data/knowledge/knowledge.db.bak_${TS}"
cp "$DB" "$BACKUP"
echo "✅ Backup created: $BACKUP"
echo

# 3) ضبط حالة الـ curriculum_phase (تعيين Phase نشطة واحدة فقط)
echo "▶ ضبط حالة المناهج (curriculum_phase) في knowledge.db ..."
sqlite3 "$DB" <<SQL
.headers on
.mode column

-- عرض الوضع الحالي للمراحل (قبل التعديل)
SELECT item_key,
       CASE
         WHEN meta_json LIKE '%"is_current": true%' THEN 'CURRENT'
         WHEN meta_json LIKE '%"is_current": false%' THEN 'INACTIVE'
         ELSE 'UNKNOWN'
       END AS old_state,
       substr(meta_json,1,120) AS meta_json_prefix
FROM knowledge_items
WHERE item_type='curriculum_phase';

-- 3.1 إلغاء أي is_current=true قديمة لكل المراحل
UPDATE knowledge_items
SET meta_json = REPLACE(meta_json, '"is_current": true', '"is_current": false')
WHERE item_type='curriculum_phase'
  AND meta_json LIKE '%"is_current": true%';

-- 3.2 تعيين PHASE_KEY كمرحلة نشطة (is_current=true)
UPDATE knowledge_items
SET meta_json = REPLACE(meta_json, '"is_current": false', '"is_current": true')
WHERE item_type='curriculum_phase'
  AND item_key = '$PHASE_KEY'
  AND meta_json LIKE '%"is_current": false%';

-- 3.3 عرض الوضع بعد التعديل
SELECT item_key,
       CASE
         WHEN meta_json LIKE '%"is_current": true%' THEN 'CURRENT'
         WHEN meta_json LIKE '%"is_current": false%' THEN 'INACTIVE'
         ELSE 'UNKNOWN'
       END AS new_state
FROM knowledge_items
WHERE item_type='curriculum_phase';
SQL

echo
echo "✅ تم ضبط حالة المناهج. مرحلة نشطة حالياً (حسب DB) موضحة أعلاه."
echo

# 4) ملخص الدروس (Lessons) من القرص ومن DB
echo "=================================================="
echo "4) ملخص الدروس (Lessons)"
echo "=================================================="

echo
echo "📂 دروس على القرص (ai/memory/lessons/*.json):"
if ls "$ROOT/ai/memory/lessons"/*.json >/dev/null 2>&1; then
  ls -1 "$ROOT/ai/memory/lessons"/*.json | sed 's/^/  - /'
else
  echo "  (لا توجد ملفات lessons على القرص)"
fi

echo
echo "🧠 دروس داخل knowledge.db (item_type='lesson'):"
sqlite3 "$DB" <<'SQL'
.headers off
.mode list
SELECT '  - key='||item_key||' | title='||IFNULL(title,'')
FROM knowledge_items
WHERE item_type='lesson';
SQL

echo
echo "📊 إحصائيات knowledge_items حسب النوع:"
sqlite3 "$DB" <<'SQL'
.headers off
.mode list
SELECT item_type||'|'||COUNT(*)
FROM knowledge_items
GROUP BY item_type;
SQL

echo
echo "✅ hf_fix_brain_state.sh انتهى بدون تعديل أي سكربتات أخرى."
