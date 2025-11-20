#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "📊 Hyper Factory – Self Evaluation System"
echo "=========================================="
echo "⏰ $(date)"

# 1. التقييم الذاتي للأداء
echo "1. 🎯 التقييم الذاتي الشامل..."
sqlite3 "$DB_PATH" "
-- إنشاء جدول التقييمات إذا لم يكن موجوداً
CREATE TABLE IF NOT EXISTS performance_evaluations (
    evaluation_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT,
    evaluation_type TEXT,
    score INTEGER,
    feedback TEXT,
    recommendations TEXT,
    evaluated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- تقييم أداء العمال بناءً على مؤشرات متعددة
INSERT INTO performance_evaluations (agent_id, evaluation_type, score, feedback, recommendations)
SELECT 
    a.id,
    'comprehensive_performance',
    CASE 
        WHEN a.success_rate >= 90 THEN 95
        WHEN a.success_rate >= 80 THEN 85
        WHEN a.success_rate >= 70 THEN 75
        WHEN a.success_rate >= 60 THEN 65
        ELSE 50
    END +
    CASE 
        WHEN a.total_runs >= 20 THEN 5
        WHEN a.total_runs >= 10 THEN 3
        WHEN a.total_runs >= 5 THEN 1
        ELSE 0
    END as final_score,
    'التقييم الذاتي: معدل نجاح ' || a.success_rate || '٪ مع ' || a.total_runs || ' مهمة منفذة',
    CASE 
        WHEN a.success_rate < 70 THEN 'مطلوب تحسين فوري في الجودة والتدريب المركز'
        WHEN a.success_rate < 80 THEN 'بحاجة لمزيد من التطوير في المهارات المتخصصة'
        WHEN a.success_rate < 90 THEN 'أداء جيد، يمكن التطوير لمستوى متقدم'
        ELSE 'أداء متميز، جاهز لمهام قيادية ومتقدمة'
    END as improvement_plan
FROM agents a
WHERE a.total_runs > 0
AND NOT EXISTS (
    SELECT 1 FROM performance_evaluations 
    WHERE agent_id = a.id 
    AND evaluated_at > datetime('now', '-7 days')
);

SELECT '✅ تم إجراء ' || changes() || ' تقييم أداء' AS result;
"

# 2. تحليل احتياجات التطوير الذاتي
echo "2. 🔍 تحليل احتياجات التطوير الذاتي..."
sqlite3 "$DB_PATH" "
-- اكتشاف مجالات التطوير المطلوبة
WITH development_needs AS (
    SELECT 
        pe.agent_id,
        pe.score,
        pe.recommendations,
        COUNT(DISTINCT ask.skill_name) as skills_count,
        AVG(ask.current_level) as avg_skill_level
    FROM performance_evaluations pe
    LEFT JOIN agent_skills ask ON pe.agent_id = ask.agent_id
    WHERE pe.evaluated_at > datetime('now', '-1 day')
    GROUP BY pe.agent_id, pe.score, pe.recommendations
    HAVING avg_skill_level < 80 OR skills_count < 3
)
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'self_evaluation_system',
    'خطة تطوير ذاتي: ' || 
    CASE 
        WHEN dn.score < 60 THEN 'تحول جذري للأداء'
        WHEN dn.score < 70 THEN 'تحسين أداء مكثف'
        WHEN dn.score < 80 THEN 'تطوير مهارات متقدمة'
        ELSE 'تأهيل قيادي وتخصصي'
    END || ' للعامل ' || dn.agent_id,
    'coaching',
    CASE 
        WHEN dn.score < 60 THEN 'high'
        WHEN dn.score < 70 THEN 'high'
        ELSE 'normal'
    END,
    'queued'
FROM development_needs dn
WHERE NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%خطة تطوير%' 
    AND description LIKE '%' || dn.agent_id || '%'
    AND created_at > datetime('now', '-30 days')
);

SELECT '✅ تم إنشاء ' || changes() || ' خطة تطوير ذاتي' AS result;
"

# 3. إنشاء مسارات تعلم مخصصة
echo "3. 🛣️ إنشاء مسارات تعلم مخصصة..."
sqlite3 "$DB_PATH" "
-- تصميم مسارات تعلم شخصية
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'self_evaluation_system',
    'مسار تعلم مخصص: ' || a.id || 
    ' - تركيز على ' || 
    (
        SELECT GROUP_CONCAT(DISTINCT 
            CASE task_type
                WHEN 'debug' THEN 'حل المشكلات'
                WHEN 'architecture' THEN 'التصميم المعماري'
                WHEN 'coaching' THEN 'التدريب والتوجيه'
                WHEN 'knowledge' THEN 'البحث والمعرفة'
                ELSE 'المهارات العامة'
            END
        )
        FROM task_assignments ta 
        JOIN tasks t ON ta.task_id = t.id 
        WHERE ta.agent_id = a.id 
        AND ta.result_status = 'success'
        LIMIT 3
    ),
    'knowledge',
    'normal',
    'queued'
FROM agents a
WHERE a.total_runs >= 5
AND a.success_rate BETWEEN 60 AND 85
AND NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%مسار تعلم%' 
    AND description LIKE '%' || a.id || '%'
    AND created_at > datetime('now', '-30 days')
)
LIMIT 3;

SELECT '✅ تم إنشاء ' || changes() || ' مسار تعلم مخصص' AS result;
"

# 4. تقارير التقدم الذاتي
echo "4. 📈 إنشاء تقارير التقدم الذاتي..."
sqlite3 "$DB_PATH" "
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'self_evaluation_system',
    'تقرير تقدم ذاتي: ' || a.id || 
    ' - ' || a.success_rate || '% نجاح، ' || a.total_runs || ' مهمة، ' ||
    (SELECT COUNT(*) FROM agent_skills WHERE agent_id = a.id) || ' مهارة',
    'quality',
    'low',
    'queued'
FROM agents a
WHERE a.last_updated > datetime('now', '-1 day')
AND (a.success_rate > 70 OR a.total_runs > 10)
AND NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%تقرير تقدم%' 
    AND description LIKE '%' || a.id || '%'
    AND created_at > datetime('now', '-7 days')
)
LIMIT 5;

SELECT '✅ تم إنشاء ' || changes() || ' تقرير تقدم ذاتي' AS result;
"

echo "📊 إحصائيات التقييم الذاتي:"
sqlite3 "$DB_PATH" "
SELECT '🎯 التقييمات: ' || COUNT(*) || ' تقييم حديث' FROM performance_evaluations WHERE evaluated_at > datetime('now', '-7 days');
SELECT '📈 متوسط الأداء: ' || ROUND(AVG(score), 1) || '%' FROM performance_evaluations WHERE evaluated_at > datetime('now', '-7 days');
SELECT '🛣️ مسارات التعلم: ' || COUNT(*) || ' مسار نشط' FROM tasks WHERE description LIKE '%مسار تعلم%';
SELECT '📋 خطط التطوير: ' || COUNT(*) || ' خطة تطوير' FROM tasks WHERE description LIKE '%خطة تطوير%';
"

echo "✅ Self Evaluation System اكتمل"
