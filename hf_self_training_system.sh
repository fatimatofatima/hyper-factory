#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
KNOWLEDGE_DB="$ROOT/data/knowledge/knowledge.db"

echo "🎓 Hyper Factory – Self Training System"
echo "========================================"
echo "⏰ $(date)"

# 1. تحليل فجوات المهارات تلقائياً
echo "1. 📊 تحليل فجوات المهارات الذاتي..."
sqlite3 "$DB_PATH" "
-- إنشاء جدول تتبع المهارات إذا لم يكن موجوداً
CREATE TABLE IF NOT EXISTS agent_skills (
    agent_id TEXT,
    skill_name TEXT,
    current_level INTEGER DEFAULT 0,
    target_level INTEGER DEFAULT 100,
    last_trained TIMESTAMP,
    PRIMARY KEY (agent_id, skill_name)
);

-- تحديث مهارات العمال بناءً على الأداء
INSERT OR REPLACE INTO agent_skills (agent_id, skill_name, current_level, last_trained)
SELECT 
    a.id,
    CASE 
        WHEN t.task_type = 'debug' THEN 'problem_solving'
        WHEN t.task_type = 'architecture' THEN 'system_design'
        WHEN t.task_type = 'coaching' THEN 'knowledge_transfer'
        WHEN t.task_type = 'knowledge' THEN 'research_skills'
        WHEN t.task_type = 'quality' THEN 'quality_assurance'
        ELSE 'general_skills'
    END as skill_name,
    CASE 
        WHEN ta.result_status = 'success' THEN 
            COALESCE((SELECT current_level FROM agent_skills WHERE agent_id = a.id AND skill_name = 
                CASE 
                    WHEN t.task_type = 'debug' THEN 'problem_solving'
                    WHEN t.task_type = 'architecture' THEN 'system_design'
                    WHEN t.task_type = 'coaching' THEN 'knowledge_transfer'
                    WHEN t.task_type = 'knowledge' THEN 'research_skills'
                    WHEN t.task_type = 'quality' THEN 'quality_assurance'
                    ELSE 'general_skills'
                END), 0) + 5
        ELSE 
            COALESCE((SELECT current_level FROM agent_skills WHERE agent_id = a.id AND skill_name = 
                CASE 
                    WHEN t.task_type = 'debug' THEN 'problem_solving'
                    WHEN t.task_type = 'architecture' THEN 'system_design'
                    WHEN t.task_type = 'coaching' THEN 'knowledge_transfer'
                    WHEN t.task_type = 'knowledge' THEN 'research_skills'
                    WHEN t.task_type = 'quality' THEN 'quality_assurance'
                    ELSE 'general_skills'
                END), 0) - 2
    END as new_level,
    CASE 
        WHEN ta.result_status = 'success' THEN CURRENT_TIMESTAMP
        ELSE (SELECT last_trained FROM agent_skills WHERE agent_id = a.id AND skill_name = 
            CASE 
                WHEN t.task_type = 'debug' THEN 'problem_solving'
                WHEN t.task_type = 'architecture' THEN 'system_design'
                WHEN t.task_type = 'coaching' THEN 'knowledge_transfer'
                WHEN t.task_type = 'knowledge' THEN 'research_skills'
                WHEN t.task_type = 'quality' THEN 'quality_assurance'
                ELSE 'general_skills'
            END)
    END as training_date
FROM agents a
JOIN task_assignments ta ON a.id = ta.agent_id
JOIN tasks t ON ta.task_id = t.id
WHERE ta.completed_at IS NOT NULL
AND ta.completed_at > datetime('now', '-24 hours');

SELECT '✅ تم تحديث ' || changes() || ' مهارة للعمال' AS result;
"

# 2. إنشاء تدريبات ذكية بناءً على فجوات المهارات
echo "2. 🏋️ إنشاء تدريبات ذكية تلقائياً..."
sqlite3 "$DB_PATH" "
-- اكتشاف المهارات التي تحتاج تحسين
WITH skill_gaps AS (
    SELECT 
        agent_id,
        skill_name,
        current_level,
        target_level,
        (target_level - current_level) as gap
    FROM agent_skills
    WHERE current_level < 70
    AND (last_trained IS NULL OR last_trained < datetime('now', '-7 days'))
    ORDER BY gap DESC
    LIMIT 5
)
-- إنشاء تدريبات مخصصة
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'self_training_system',
    'تدريب مخصص: تحسين ' || 
    CASE sg.skill_name
        WHEN 'problem_solving' THEN 'مهارات حل المشكلات'
        WHEN 'system_design' THEN 'التصميم المعماري للأنظمة'
        WHEN 'knowledge_transfer' THEN 'نقل المعرفة والتدريب'
        WHEN 'research_skills' THEN 'مهارات البحث وجمع المعلومات'
        WHEN 'quality_assurance' THEN 'مراقبة وضمان الجودة'
        ELSE 'المهارات العامة'
    END || ' للعامل ' || sg.agent_id || ' (المستوى الحالي: ' || sg.current_level || '%)',
    'coaching',
    CASE 
        WHEN sg.gap > 50 THEN 'high'
        WHEN sg.gap > 30 THEN 'normal' 
        ELSE 'low'
    END,
    'queued'
FROM skill_gaps sg
WHERE NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%' || sg.agent_id || '%' 
    AND description LIKE '%' || sg.skill_name || '%'
    AND created_at > datetime('now', '-3 days')
);

SELECT '✅ تم إنشاء ' || changes() || ' تدريب مخصص' AS result;
"

# 3. إنشاء اختبارات تقييم ذاتية
echo "3. 🧪 إنشاء اختبارات تقييم ذاتية..."
sqlite3 "$DB_PATH" "
-- إنشاء اختبارات للمهارات المحسنة
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'self_training_system',
    'اختبار تقييم: ' || 
    CASE sg.skill_name
        WHEN 'problem_solving' THEN 'قدرات حل المشكلات المعقدة'
        WHEN 'system_design' THEN 'تصميم الأنظمة المتكاملة'
        WHEN 'knowledge_transfer' THEN 'فعالية نقل المعرفة'
        WHEN 'research_skills' THEN 'جودة البحث والتحليل'
        WHEN 'quality_assurance' THEN 'دقة مراقبة الجودة'
        ELSE 'المهارات المتقدمة'
    END || ' للعامل ' || sg.agent_id,
    'coaching',
    'normal',
    'queued'
FROM agent_skills sg
WHERE sg.current_level >= 70
AND sg.current_level < 90
AND NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%اختبار تقييم%' 
    AND description LIKE '%' || sg.agent_id || '%'
    AND created_at > datetime('now', '-14 days')
)
LIMIT 3;

SELECT '✅ تم إنشاء ' || changes() || ' اختبار تقييم' AS result;
"

# 4. توليد مراجع تدريبية من المعرفة المتراكمة
echo "4. 📖 توليد مراجع تدريبية ذكية..."
TRAINING_TOPICS=$(sqlite3 "$KNOWLEDGE_DB" "
SELECT topic FROM knowledge_base 
WHERE quality_score > 75 
AND last_updated > datetime('now', '-7 days')
ORDER BY quality_score DESC 
LIMIT 3
")

for topic in $TRAINING_TOPICS; do
    echo "📚 إنشاء مرجع تدريبي: $topic"
    
    sqlite3 "$DB_PATH" "
    INSERT INTO tasks (created_at, source, description, task_type, priority, status)
    VALUES (
        CURRENT_TIMESTAMP,
        'self_training_system',
        'مرجع تدريبي: ' || '$topic' || ' - استخلاص من المعرفة المتراكمة',
        'knowledge',
        'normal',
        'queued'
    );
    "
done

echo "🎓 إحصائيات النظام التدريبي الذاتي:"
sqlite3 "$DB_PATH" "
SELECT '📊 المهارات: ' || COUNT(*) || ' مهارة مُتتبعة' FROM agent_skills;
SELECT '📈 يحتاج تحسين: ' || COUNT(*) || ' مهارة' FROM agent_skills WHERE current_level < 70;
SELECT '🏆 متقدم: ' || COUNT(*) || ' مهارة' FROM agent_skills WHERE current_level >= 80;
SELECT '🎯 التدريبات: ' || COUNT(*) || ' تدريب نشط' FROM tasks WHERE source = 'self_training_system';
"

echo "✅ Self Training System اكتمل"
