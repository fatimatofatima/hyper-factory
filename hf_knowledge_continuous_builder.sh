#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🧠 Hyper Factory – Continuous Knowledge Builder"
echo "================================================"
echo "⏰ $(date)"

# 1. بناء معرفة من الأنماط المكتشفة
echo "1. 📊 بناء معرفة من أنماط الأداء..."
sqlite3 "$DB_PATH" "
-- تحويل الأنماط إلى معرفة
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'knowledge_builder',
    'توثيق نمط أداء: العامل ' || a.id || ' متفوق في مهام ' || 
    (SELECT GROUP_CONCAT(DISTINCT task_type) FROM task_assignments WHERE agent_id = a.id AND result_status = 'success') ||
    ' (معدل نجاح ' || a.success_rate || '%)',
    'knowledge',
    'high',
    'queued'
FROM agents a
WHERE a.success_rate > 80 
AND a.total_runs >= 3
AND NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%' || a.id || '%'
    AND created_at > datetime('now', '-1 day')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة توثيق أنماط' AS result;
"

# 2. بناء معرفة من الأخطاء
echo "2. 🔧 بناء معرفة من الدروس المستفادة..."
sqlite3 "$DB_PATH" "
-- تحويل الأخطاء إلى معرفة
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'knowledge_builder',
    'توثيق درس مستفاد: تجنب ' || t.task_type || ' مع ' || ta.agent_id ||
    ' بعد ' || COUNT(*) || ' فشل',
    'knowledge',
    'high',
    'queued'
FROM task_assignments ta
JOIN tasks t ON ta.task_id = t.id
WHERE ta.result_status = 'fail'
AND ta.completed_at > datetime('now', '-1 hour')
GROUP BY ta.agent_id, t.task_type
HAVING COUNT(*) >= 2
AND NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%' || ta.agent_id || '%' 
    AND description LIKE '%' || t.task_type || '%'
    AND created_at > datetime('now', '-1 day')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة دروس مستفادة' AS result;
"

# 3. بناء معرفة من النجاحات
echo "3. 🎯 بناء معرفة من أفضل الممارسات..."
sqlite3 "$DB_PATH" "
-- تحويل النجاحات إلى معرفة
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'knowledge_builder',
    'توثيق أفضل ممارسة: ' || t.task_type || ' ناجح مع ' || ta.agent_id ||
    ' (' || COUNT(*) || ' نجاح متتالي)',
    'knowledge',
    'normal',
    'queued'
FROM task_assignments ta
JOIN tasks t ON ta.task_id = t.id
WHERE ta.result_status = 'success'
AND ta.completed_at > datetime('now', '-1 hour')
GROUP BY ta.agent_id, t.task_type
HAVING COUNT(*) >= 3
AND NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%' || ta.agent_id || '%' 
    AND description LIKE '%' || t.task_type || '%'
    AND created_at > datetime('now', '-6 hours')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة أفضل ممارسات' AS result;
"

echo "📚 إحصائيات المعرفة المبنية:"
sqlite3 "$DB_PATH" "
SELECT '🧠 المعرفة: ' || COUNT(*) || ' مهمة معرفة نشطة' FROM tasks WHERE task_type = 'knowledge' AND status IN ('queued', 'assigned');
SELECT '📊 الأنماط: ' || COUNT(*) || ' نمط موثق' FROM tasks WHERE source = 'knowledge_builder' AND description LIKE '%نمط%';
SELECT '🎓 الدروس: ' || COUNT(*) || ' درس مستفاد' FROM tasks WHERE source = 'knowledge_builder' AND description LIKE '%درس%';
SELECT '⭐ الممارسات: ' || COUNT(*) || ' أفضل ممارسة' FROM tasks WHERE source = 'knowledge_builder' AND description LIKE '%ممارسة%';
"

echo "✅ Continuous Knowledge Builder اكتمل"
