#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🎓 Hyper Factory – Continuous Training Generator"
echo "================================================"
echo "⏰ $(date)"

# 1. إنشاء تدريبات للمهارات الضعيفة
echo "1. 📈 إنشاء تدريبات للمهارات الضعيفة..."
sqlite3 "$DB_PATH" "
-- اكتشاف نقاط الضعف وإنشاء تدريبات
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'training_generator',
    'تدريب تحسين: ' || 
    CASE 
        WHEN task_type = 'debug' THEN 'مهارات التصحيح'
        WHEN task_type = 'architecture' THEN 'التصميم المعماري' 
        WHEN task_type = 'coaching' THEN 'التدريب التقني'
        WHEN task_type = 'knowledge' THEN 'البحث وجمع المعلومات'
        ELSE 'المهارات العامة'
    END || ' للعامل ' || agent_id,
    'coaching',
    'high',
    'queued'
FROM (
    SELECT 
        ta.agent_id,
        t.task_type,
        COUNT(*) as fail_count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM task_assignments WHERE agent_id = ta.agent_id), 2) as fail_rate
    FROM task_assignments ta
    JOIN tasks t ON ta.task_id = t.id
    WHERE ta.result_status = 'fail'
    AND ta.completed_at > datetime('now', '-2 hours')
    GROUP BY ta.agent_id, t.task_type
    HAVING fail_count >= 2 AND fail_rate > 40.0
    LIMIT 3
)
WHERE NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE source = 'training_generator' 
    AND description LIKE '%' || agent_id || '%'
    AND created_at > datetime('now', '-3 hours')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة تدريب تحسين' AS result;
"

# 2. إنشاء اختبارات للمهارات المتقدمة
echo "2. 🧪 إنشاء اختبارات للمهارات المتقدمة..."
sqlite3 "$DB_PATH" "
-- إنشاء اختبارات للتطوير
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'training_generator',
    'اختبار متقدم: ' || 
    CASE 
        WHEN task_type = 'debug' THEN 'تصحيح أخطاء معقدة'
        WHEN task_type = 'architecture' THEN 'تصميم أنظمة متكاملة'
        WHEN task_type = 'coaching' THEN 'تدريب فرق متعددة'
        WHEN task_type = 'knowledge' THEN 'إدارة معرفة متقدمة'
        ELSE 'تحديات متقدمة'
    END || ' للعامل ' || agent_id,
    'coaching',
    'normal',
    'queued'
FROM (
    SELECT 
        ta.agent_id,
        t.task_type,
        COUNT(*) as success_count
    FROM task_assignments ta
    JOIN tasks t ON ta.task_id = t.id
    WHERE ta.result_status = 'success'
    AND ta.completed_at > datetime('now', '-3 hours')
    GROUP BY ta.agent_id, t.task_type
    HAVING success_count >= 5
    LIMIT 2
)
WHERE NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE source = 'training_generator' 
    AND description LIKE '%اختبار متقدم%'
    AND description LIKE '%' || agent_id || '%'
    AND created_at > datetime('now', '-6 hours')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة اختبار متقدم' AS result;
"

# 3. إنشاء تمارين للمهارات الجديدة
echo "3. 🆕 إنشاء تمارين للمهارات الجديدة..."
sqlite3 "$DB_PATH" "
-- تمارين لمهارات لم يتم تغطيتها
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'training_generator',
    'تمرين جديد: ' || 
    CASE 
        WHEN task_type = 'quality' THEN 'مراقبة الجودة والتدقيق'
        WHEN task_type = 'pipeline' THEN 'إدارة خطوط الإنتاج'
        ELSE 'مهارات متخصصة'
    END || ' لتوسيع خبرات العاملين',
    'coaching',
    'normal',
    'queued'
FROM (
    SELECT DISTINCT 'quality' as task_type
    FROM tasks 
    WHERE task_type = 'quality' 
    AND created_at > datetime('now', '-1 day')
    AND NOT EXISTS (
        SELECT 1 FROM task_assignments 
        WHERE task_id IN (SELECT id FROM tasks WHERE task_type = 'quality')
    )
    UNION ALL
    SELECT DISTINCT 'pipeline' as task_type
    FROM tasks 
    WHERE task_type = 'pipeline' 
    AND created_at > datetime('now', '-1 day')
    LIMIT 1
)
WHERE NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE source = 'training_generator' 
    AND description LIKE '%تمرين جديد%'
    AND created_at > datetime('now', '-12 hours')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة تمرين جديد' AS result;
"

echo "🎓 إحصائيات التدريب والاختبارات:"
sqlite3 "$DB_PATH" "
SELECT '📚 التدريبات: ' || COUNT(*) || ' مهمة تدريب نشطة' FROM tasks WHERE task_type = 'coaching' AND status IN ('queued', 'assigned');
SELECT '🔍 التحسين: ' || COUNT(*) || ' تدريب تحسين' FROM tasks WHERE source = 'training_generator' AND description LIKE '%تحسين%';
SELECT '🧪 الاختبارات: ' || COUNT(*) || ' اختبار متقدم' FROM tasks WHERE source = 'training_generator' AND description LIKE '%اختبار%';
SELECT '🆕 التمارين: ' || COUNT(*) || ' تمرين جديد' FROM tasks WHERE source = 'training_generator' AND description LIKE '%تمرين جديد%';
"

echo "✅ Continuous Training Generator اكتمل"
