#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🔄 Hyper Factory – Fixed Performance Updater"
echo "============================================"
echo "⏰ $(date)"
echo "📄 DB: $DB_PATH"
echo ""

# 1) فحص هيكل الجدول أولاً
echo "🔍 فحص هيكل جدول agents:"
sqlite3 "$DB_PATH" "PRAGMA table_info(agents);"

echo ""
echo "📈 تحديث success_rate و total_runs..."

# 2) تحديث الأداء بناءً على المهام المكتملة
sqlite3 "$DB_PATH" "
UPDATE agents 
SET success_rate = (
    SELECT 
        CASE 
            WHEN COUNT(t.id) = 0 THEN 0
            ELSE ROUND((SUM(CASE WHEN t.status = 'done' THEN 1 ELSE 0 END) * 100.0 / COUNT(t.id)), 2)
        END
    FROM tasks t
    WHERE t.assigned_agent = agents.id
),
total_runs = (
    SELECT COUNT(t.id)
    FROM tasks t
    WHERE t.assigned_agent = agents.id
)
WHERE id IN (SELECT DISTINCT assigned_agent FROM tasks WHERE assigned_agent IS NOT NULL);
"

echo "✅ تم تحديث أداء العمال"

echo ""
echo "📊 عرض البيانات المحدثة (باستخدام display_name):"
sqlite3 -header -column "$DB_PATH" "
SELECT 
    id as 'Agent_ID',
    display_name as 'Name', 
    family as 'Family',
    success_rate as 'Success_%',
    total_runs as 'Total_Runs'
FROM agents 
WHERE total_runs > 0 
ORDER BY total_runs DESC 
LIMIT 10;
"

echo ""
echo "🏆 أفضل العمال حسب معدل النجاح:"
sqlite3 -header -column "$DB_PATH" "
SELECT 
    id as 'Agent_ID',
    display_name as 'Name', 
    family as 'Family',
    success_rate as 'Success_%',
    total_runs as 'Total_Runs'
FROM agents 
WHERE total_runs >= 3 
ORDER BY success_rate DESC 
LIMIT 5;
"

echo ""
echo "✅ Fixed Performance Update اكتمل"
