#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🔄 Hyper Factory – Auto Performance Updater"
echo "==========================================="
echo "⏰ \$(date)"
echo "📄 DB: \$DB_PATH"
echo ""

sqlite3 "\$DB_PATH" "
-- تحديث success_rate و total_runs لكل عامل بناءً على المهام المكتملة
UPDATE agents
SET
  success_rate = (
    SELECT 
      CASE 
        WHEN COUNT(*) > 0 THEN 
          ROUND(
            SUM(CASE WHEN ta.result_status = 'success' THEN 1 ELSE 0 END) * 100.0 
            / COUNT(*),
            2
          )
        ELSE 0
      END
    FROM task_assignments ta
    WHERE ta.agent_id = agents.id
      AND ta.completed_at IS NOT NULL
  ),
  total_runs = (
    SELECT 
      COUNT(*)
    FROM task_assignments ta
    WHERE ta.agent_id = agents.id
      AND ta.completed_at IS NOT NULL
  )
WHERE id IN (
  SELECT DISTINCT agent_id 
  FROM task_assignments 
  WHERE completed_at IS NOT NULL
);

-- تقرير سريع عن التحديث
SELECT 
  '✅ تم تحديث أداء ' || COUNT(*) || ' عامل' AS result
FROM agents
WHERE id IN (
  SELECT DISTINCT agent_id 
  FROM task_assignments 
  WHERE completed_at IS NOT NULL
);
"

echo "✅ Auto Performance Update اكتمل"
