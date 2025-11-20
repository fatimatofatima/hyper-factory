#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🔄 Hyper Factory – Auto Performance Updater"
echo "==========================================="
echo "⏰ $(date)"
echo "📄 DB: $DB_PATH"
echo ""

# 0) تأكد أن ملف قاعدة البيانات موجود
if [ ! -f "$DB_PATH" ]; then
    echo "❌ قاعدة البيانات غير موجودة: $DB_PATH"
    exit 1
fi

echo "📋 فحص الجداول في قاعدة البيانات..."
TABLES=$(sqlite3 "$DB_PATH" ".tables" 2>/dev/null || echo "")
echo "   Tables: $TABLES"
echo ""

# نحتاج agents + tasks + task_assignments
for tbl in agents tasks task_assignments; do
    if ! echo "$TABLES" | grep -qw "$tbl"; then
        echo "❌ جدول $tbl غير موجود في $DB_PATH"
        exit 1
    fi
done

echo "📈 تحديث success_rate و total_runs لكل عامل بناءً على المهام المكتملة/الفاشلة..."
echo ""

sqlite3 "$DB_PATH" "
UPDATE agents
SET
  total_runs = COALESCE((
    SELECT COUNT(*)
    FROM task_assignments ta
    JOIN tasks t ON t.id = ta.task_id
    WHERE ta.agent_id = agents.id
      AND t.status IN ('done','failed')
  ), 0),
  success_rate = COALESCE((
    SELECT 
      CASE 
        WHEN COUNT(*) = 0 THEN 0
        ELSE ROUND(
          100.0 * SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END)
                / COUNT(*)
          , 2
        )
      END
    FROM task_assignments ta
    JOIN tasks t ON t.id = ta.task_id
    WHERE ta.agent_id = agents.id
      AND t.status IN ('done','failed')
  ), 0),
  last_updated = CURRENT_TIMESTAMP;
"

echo "📊 أعلى 5 عمال حسب عدد التشغيل:"
sqlite3 -header -column "$DB_PATH" "
SELECT
  id            AS agent_id,
  display_name  AS name,
  family,
  role,
  level,
  success_rate,
  total_runs
FROM agents
ORDER BY total_runs DESC
LIMIT 5;
" 2>/dev/null || echo "⚠️ تعذر عرض أعلى العمال (تابع العمل بدون إيقاف)."

echo ""
echo "✅ Auto Performance Update اكتمل"
