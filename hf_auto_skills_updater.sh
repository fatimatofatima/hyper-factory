#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "📈 Hyper Factory – Auto Skills Updater"
echo "======================================"

# خريطة ربط أنواع المهام بالمهارات
sqlite3 "$DB_PATH" "
-- ربط المهام الناجحة بتحسين المهارات
INSERT OR REPLACE INTO user_skills (user_id, skill_id, level, last_updated)
SELECT 
    'system_user' as user_id,
    CASE 
        WHEN t.task_type = 'debug' THEN 'debug_skills'
        WHEN t.task_type = 'architecture' THEN 'system_design'
        WHEN t.task_type = 'coaching' THEN 'teaching_skills'
        WHEN t.task_type = 'knowledge' THEN 'research_skills'
        WHEN t.task_type = 'quality' THEN 'quality_assurance'
        WHEN t.task_type = 'pipeline' THEN 'data_pipeline'
        ELSE 'general_skills'
    END as skill_id,
    COALESCE(us.level, 0) + 5 as new_level,  -- +5 نقاط لكل مهمة ناجحة
    CURRENT_TIMESTAMP
FROM task_assignments ta
JOIN tasks t ON ta.task_id = t.id
LEFT JOIN user_skills us ON us.user_id = 'system_user' 
    AND us.skill_id = CASE 
        WHEN t.task_type = 'debug' THEN 'debug_skills'
        WHEN t.task_type = 'architecture' THEN 'system_design'
        WHEN t.task_type = 'coaching' THEN 'teaching_skills'
        WHEN t.task_type = 'knowledge' THEN 'research_skills'
        WHEN t.task_type = 'quality' THEN 'quality_assurance'
        WHEN t.task_type = 'pipeline' THEN 'data_pipeline'
        ELSE 'general_skills'
    END
WHERE ta.result_status = 'success'
AND ta.completed_at > datetime('now', '-1 day')
ON CONFLICT(user_id, skill_id) DO UPDATE SET
    level = excluded.level,
    last_updated = excluded.last_updated;

-- عرض التغييرات
SELECT '✅ تم تحديث ' || changes() || ' مهارة' AS result;
"

echo "📊 ملخص المهارات الحالية:"
sqlite3 "$DB_PATH" "
SELECT skill_id, level 
FROM user_skills 
WHERE user_id = 'system_user'
ORDER BY level DESC;"

echo "✅ Auto Skills Update اكتمل"
