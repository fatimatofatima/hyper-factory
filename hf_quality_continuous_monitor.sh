#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🎯 Hyper Factory – Continuous Quality Monitor"
echo "============================================="
echo "⏰ $(date)"

# 1. مراقبة جودة الأداء المستمر
echo "1. 📊 مراقبة جودة الأداء المستمر..."
sqlite3 "$DB_PATH" "
-- مراقبة انخفاض الأداء
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'quality_monitor',
    'تدقيق جودة: انخفاض أداء العامل ' || a.id || 
    ' من ' || ROUND(a_old.success_rate, 1) || '% إلى ' || ROUND(a.success_rate, 1) || '%',
    'quality',
    'high',
    'queued'
FROM agents a
JOIN (
    SELECT id, success_rate 
    FROM agents 
    WHERE last_updated < datetime('now', '-30 minutes')
) a_old ON a.id = a_old.id
WHERE a.success_rate < (a_old.success_rate - 10)
AND a.total_runs >= 5
AND NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%' || a.id || '%'
    AND created_at > datetime('now', '-1 hour')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة تدقيق جودة' AS result;
"

# 2. مراقبة تكرار الأخطاء
echo "2. 🔍 مراقبة تكرار الأخطاء..."
sqlite3 "$DB_PATH" "
-- اكتشاف تسارع الأخطاء
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'quality_monitor',
    'تحقيق جودة: تسارع أخطاء ' || task_type || 
    ' (' || error_count || ' خطأ في آخر ساعة)',
    'quality',
    'high',
    'queued'
FROM (
    SELECT 
        t.task_type,
        COUNT(*) as error_count
    FROM task_assignments ta
    JOIN tasks t ON ta.task_id = t.id
    WHERE ta.result_status = 'fail'
    AND ta.completed_at > datetime('now', '-1 hour')
    GROUP BY t.task_type
    HAVING error_count >= 3
)
WHERE NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%' || task_type || '%'
    AND created_at > datetime('now', '-2 hours')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة تحقيق جودة' AS result;
"

# 3. مراقبة توازن التوزيع
echo "3. ⚖️ مراقبة توازن التوزيع..."
sqlite3 "$DB_PATH" "
-- مراقبة عدالة توزيع المهام
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'quality_monitor',
    'مراجعة توزيع: العامل ' || agent_id || 
    ' مشغول ب' || task_count || ' مهمة بينما المتوسط ' || ROUND(avg_tasks, 1),
    'quality',
    'normal',
    'queued'
FROM (
    SELECT 
        ta.agent_id,
        COUNT(*) as task_count,
        (SELECT AVG(cnt) FROM (SELECT COUNT(*) as cnt FROM task_assignments WHERE assigned_at > datetime('now', '-6 hours') GROUP BY agent_id)) as avg_tasks
    FROM task_assignments ta
    WHERE ta.assigned_at > datetime('now', '-6 hours')
    AND ta.result_status IS NULL
    GROUP BY ta.agent_id
    HAVING task_count > (avg_tasks * 1.5)
    AND task_count >= 5
)
WHERE NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%' || agent_id || '%'
    AND created_at > datetime('now', '-3 hours')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة مراجعة توزيع' AS result;
"

echo "🎯 إحصائيات الجودة:"
sqlite3 "$DB_PATH" "
SELECT '🔍 المراقبة: ' || COUNT(*) || ' مهمة جودة نشطة' FROM tasks WHERE task_type = 'quality' AND status IN ('queued', 'assigned');
SELECT '📉 الانخفاض: ' || COUNT(*) || ' تدقيق أداء' FROM tasks WHERE source = 'quality_monitor' AND description LIKE '%انخفاض%';
SELECT '🚨 الأخطاء: ' || COUNT(*) || ' تحقيق أخطاء' FROM tasks WHERE source = 'quality_monitor' AND description LIKE '%تسارع%';
SELECT '⚖️ التوزيع: ' || COUNT(*) || ' مراجعة توزيع' FROM tasks WHERE source = 'quality_monitor' AND description LIKE '%توزيع%';
"

echo "✅ Continuous Quality Monitor اكتمل"
