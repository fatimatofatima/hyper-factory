#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🧠 Hyper Factory – Knowledge Builder"
echo "===================================="

# تحليل الأنماط وإنشاء مهام معرفة
sqlite3 "$DB_PATH" "
-- تحليل المهام الناجحة والفاشلة لاكتشاف أنماط
WITH task_patterns AS (
    SELECT 
        task_type,
        COUNT(*) as total_tasks,
        SUM(CASE WHEN result_status = 'success' THEN 1 ELSE 0 END) as success_count,
        AVG(CASE WHEN result_status = 'success' THEN 1.0 ELSE 0 END) as success_rate
    FROM task_assignments ta
    JOIN tasks t ON ta.task_id = t.id
    WHERE ta.completed_at IS NOT NULL
    GROUP BY task_type
),
knowledge_gaps AS (
    SELECT 
        task_type,
        success_rate,
        CASE 
            WHEN success_rate < 0.7 THEN 'عالية'
            WHEN success_rate < 0.9 THEN 'متوسطة' 
            ELSE 'منخفضة'
        END as priority_level
    FROM task_patterns
    WHERE total_tasks >= 3
)
-- إنشاء مهام معرفة لسد الفجوات
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'knowledge_builder',
    'بحث وتوثيق أفضل ممارسات لتحسين ' || 
    CASE 
        WHEN kg.task_type = 'debug' THEN 'تصحيح الأخطاء'
        WHEN kg.task_type = 'architecture' THEN 'التصميم المعماري'
        WHEN kg.task_type = 'coaching' THEN 'التدريب التقني'
        WHEN kg.task_type = 'quality' THEN 'مراقبة الجودة'
        ELSE 'المهام العامة'
    END || ' (معدل النجاح: ' || ROUND(kg.success_rate * 100, 1) || '%)',
    'knowledge',
    CASE kg.priority_level
        WHEN 'عالية' THEN 'high'
        WHEN 'متوسطة' THEN 'normal'
        ELSE 'low'
    END,
    'queued'
FROM knowledge_gaps kg
WHERE NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%' || kg.task_type || '%'
    AND status IN ('queued', 'assigned')
    AND created_at > datetime('now', '-1 day')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة معرفة' AS result;
"

echo "📚 مهام المعرفة الجديدة:"
sqlite3 "$DB_PATH" "
SELECT id, description, priority 
FROM tasks 
WHERE source = 'knowledge_builder' 
AND status = 'queued'
ORDER BY id DESC LIMIT 5;"

echo "✅ Knowledge Builder اكتمل"
