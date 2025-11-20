#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🎯 Hyper Factory – Quality & Patterns System"
echo "==========================================="

# 1. تحليل الأنماط
echo "1. 📊 تحليل أنماط الأداء..."
sqlite3 "$DB_PATH" "
-- اكتشاف أنماط الفشل المتكررة
WITH failure_patterns AS (
    SELECT 
        ta.agent_id,
        t.task_type,
        COUNT(*) as fail_count
    FROM task_assignments ta
    JOIN tasks t ON ta.task_id = t.id
    WHERE ta.result_status = 'fail'
    GROUP BY ta.agent_id, t.task_type
    HAVING fail_count >= 2
)
-- إنشاء مهام جودة للأنماط الخطيرة
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'quality_system',
    'تحسين أداء العامل ' || fp.agent_id || ' في مهام ' || fp.task_type || ' (فشل ' || fp.fail_count || ' مرات)',
    'quality',
    'high',
    'queued'
FROM failure_patterns fp
WHERE NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%' || fp.agent_id || '%'
    AND status IN ('queued', 'assigned')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة جودة' AS result;
"

# 2. تحسين قرارات المدير
echo "2. 🧠 تحسين قرارات التوزيع..."
sqlite3 "$DB_PATH" "
-- خفض أولوية العمال ذوي الأداء الضعيف
UPDATE agents 
SET priority_weight = 
    CASE 
        WHEN success_rate < 50 THEN 0.3
        WHEN success_rate < 80 THEN 0.7
        ELSE 1.0
    END
WHERE id IN (
    SELECT agent_id FROM task_assignments 
    WHERE result_status = 'fail' 
    AND completed_at > datetime('now', '-1 day')
    GROUP BY agent_id 
    HAVING COUNT(*) >= 2
);

SELECT '✅ تم تحسين أولويات ' || changes() || ' عامل' AS result;
"

echo "📈 تقرير الجودة:"
sqlite3 "$DB_PATH" "
SELECT '🔴 المشاكل: ' || COUNT(*) || ' نمط فشل مكتشف' FROM tasks WHERE source = 'quality_system';
SELECT '📊 التحسين: ' || COUNT(*) || ' عامل تم تعديل أولويته' FROM agents WHERE priority_weight < 1.0;
"

echo "✅ Quality & Patterns System اكتمل"
