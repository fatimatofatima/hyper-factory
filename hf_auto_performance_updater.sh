#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🔄 Hyper Factory – Auto Performance Updater"
echo "==========================================="

# تحليل نتائج المهام الأخيرة وتحديث success_rate
sqlite3 "$DB_PATH" "
-- حساب success_rate لكل عامل بناءً على المهام المكتملة
WITH agent_performance AS (
    SELECT 
        ta.agent_id,
        COUNT(*) as total_tasks,
        SUM(CASE WHEN ta.result_status = 'success' THEN 1 ELSE 0 END) as successful_tasks,
        CASE 
            WHEN COUNT(*) > 0 THEN 
                ROUND(SUM(CASE WHEN ta.result_status = 'success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
            ELSE 0 
        END as new_success_rate
    FROM task_assignments ta
    WHERE ta.completed_at IS NOT NULL
    GROUP BY ta.agent_id
)
-- تحديث جدول agents
UPDATE agents 
SET 
    success_rate = ap.new_success_rate,
    total_runs = ap.total_tasks,
    last_updated = CURRENT_TIMESTAMP
WHERE agents.id IN (SELECT agent_id FROM agent_performance);

-- عرض التغييرات
SELECT '✅ تم تحديث أداء ' || changes() || ' عامل' AS result;
"

echo "📊 أداء العمال المحدث:"
sqlite3 "$DB_PATH" "
SELECT id, success_rate, total_runs, datetime(last_updated) as last_updated 
FROM agents 
WHERE total_runs > 0
ORDER BY success_rate DESC;"

echo "✅ Auto Performance Update اكتمل"
