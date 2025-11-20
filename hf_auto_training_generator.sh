#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🎓 Hyper Factory – Auto Training Generator"
echo "=========================================="

# إنشاء مهام تدريبية بناءً على المهارات الضعيفة
sqlite3 "$DB_PATH" "
-- البحث عن المهارات التي تحتاج تحسين
WITH weak_skills AS (
    SELECT skill_id, level
    FROM user_skills 
    WHERE user_id = 'system_user' 
    AND level < 50  -- مهارات تحتاج تحسين
    ORDER BY level ASC
    LIMIT 3
),
training_topics AS (
    SELECT 
        ws.skill_id,
        CASE 
            WHEN ws.skill_id = 'debug_skills' THEN 'تمرين تصحيح أخطاء متقدم'
            WHEN ws.skill_id = 'system_design' THEN 'تصميم بنية نظام متكامل'
            WHEN ws.skill_id = 'teaching_skills' THEN 'إعداد خطة تدريب للمبتدئين'
            WHEN ws.skill_id = 'research_skills' THEN 'بحث متقدم في تقنيات جديدة'
            WHEN ws.skill_id = 'quality_assurance' THEN 'مراجعة جودة شاملة للنظام'
            ELSE 'تمرين تطوير مهارات عامة'
        END as training_topic
    FROM weak_skills ws
)
-- إنشاء مهام تدريبية
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'training_generator',
    tt.training_topic || ' - تحسين مهارة: ' || tt.skill_id,
    CASE 
        WHEN tt.skill_id = 'debug_skills' THEN 'debug'
        WHEN tt.skill_id = 'system_design' THEN 'architecture' 
        WHEN tt.skill_id = 'teaching_skills' THEN 'coaching'
        WHEN tt.skill_id = 'research_skills' THEN 'knowledge'
        WHEN tt.skill_id = 'quality_assurance' THEN 'quality'
        ELSE 'general'
    END,
    'normal',
    'queued'
FROM training_topics tt
WHERE NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%' || tt.training_topic || '%'
    AND status IN ('queued', 'assigned')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة تدريبية' AS result;
"

echo "📋 المهام التدريبية الجديدة:"
sqlite3 "$DB_PATH" "
SELECT id, task_type, description, priority 
FROM tasks 
WHERE source = 'training_generator' 
AND status = 'queued'
ORDER BY id DESC LIMIT 5;"

echo "✅ Auto Training Generator اكتمل"
