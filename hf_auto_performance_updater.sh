#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🔄 Hyper Factory – Auto Performance Updater"
echo "==========================================="
echo "⏰ $(date)"

# تحديث أداء العمال بناءً على المهام المكتملة
sqlite3 "$DB_PATH" "
-- حساب أداء كل عامل
WITH agent_stats AS (
    SELECT 
        agent_id,
        COUNT(*) as total_tasks,
        SUM(CASE WHEN result_status = 'success' THEN 1 ELSE 0 END) as success_tasks
    FROM task_assignments 
    WHERE completed_at IS NOT NULL
    GROUP BY agent_id
)
-- تحديث جدول agents
UPDATE agents
SET 
    success_rate = CASE 
        WHEN (SELECT total_tasks FROM agent_stats WHERE agent_id = agents.id) > 0 
        THEN ROUND(
            (SELECT success_tasks FROM agent_stats WHERE agent_id = agents.id) * 100.0 / 
            (SELECT total_tasks FROM agent_stats WHERE agent_id = agents.id), 
        2)
        ELSE 0.0
    END,
    total_runs = COALESCE((SELECT total_tasks FROM agent_stats WHERE agent_id = agents.id), 0),
    last_updated = CURRENT_TIMESTAMP
WHERE id IN (SELECT agent_id FROM agent_stats);

SELECT '✅ تم تحديث أداء ' || changes() || ' عامل' AS result;
"

echo "📊 أداء العمال المحدث:"
sqlite3 "$DB_PATH" "
SELECT id, display_name, success_rate, total_runs 
FROM agents 
WHERE total_runs > 0
ORDER BY success_rate DESC;"

echo "✅ Auto Performance Update اكتمل"
