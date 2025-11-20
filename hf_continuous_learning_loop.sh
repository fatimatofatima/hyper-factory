#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

DB_PATH="$ROOT/data/factory/factory.db"
MAX_CYCLES=${1:-3}  # عدد دورات التعلم
SLEEP_TIME=${2:-30} # وقت الانتظار بين الدورات

echo "🔄 Hyper Factory – Continuous Learning Loop"
echo "==========================================="
echo "⏰ بدء التعلم المستمر: $(date)"
echo "🎯 دورات التعلم: $MAX_CYCLES"
echo "⏱️  وقت التفكير: $SLEEP_TIME ثانية"
echo ""

for ((cycle=1; cycle<=MAX_CYCLES; cycle++)); do
    echo "🧠 دورة التعلم $cycle من $MAX_CYCLES"
    echo "==============================="
    
    # 1. تشغيل المصنع الأساسي
    echo "1. 🏭 تشغيل المصنع الأساسي..."
    ./hf_full_auto_cycle.sh
    
    # 2. إنشاء مهام تدريبية بناءً على الأداء
    echo "2. 🎓 تحليل الاحتياجات التدريبية..."
    sqlite3 "$DB_PATH" "
    -- إنشاء مهام تدريبية بناءً على نقاط الضعف
    INSERT INTO tasks (created_at, source, description, task_type, priority, status)
    SELECT 
        CURRENT_TIMESTAMP,
        'learning_system',
        'تدريب على تحسين ' || 
        CASE 
            WHEN task_type = 'debug' THEN 'مهارات التصحيح'
            WHEN task_type = 'architecture' THEN 'التصميم المعماري'
            WHEN task_type = 'coaching' THEN 'التدريب التقني'
            ELSE 'المهارات العامة'
        END,
        'coaching',
        'normal',
        'queued'
    FROM (
        SELECT task_type, COUNT(*) as fail_count
        FROM task_assignments ta
        JOIN tasks t ON ta.task_id = t.id
        WHERE ta.result_status = 'fail'
        AND ta.completed_at > datetime('now', '-1 hour')
        GROUP BY task_type
        HAVING fail_count >= 2
        LIMIT 1
    )
    WHERE NOT EXISTS (
        SELECT 1 FROM tasks 
        WHERE source = 'learning_system'
        AND status IN ('queued', 'assigned')
    );
    
    SELECT '✅ تم إنشاء ' || changes() || ' مهمة تدريبية' AS result;
    "
    
    # 3. تحديث المهارات
    echo "3. 📈 تحديث المهارات التلقائي..."
    sqlite3 "$DB_PATH" "
    -- تحديث مهارات النظام بناءً على النجاحات
    INSERT OR REPLACE INTO user_skills (user_id, skill_id, level, last_updated)
    SELECT 
        'system_learner',
        CASE 
            WHEN task_type = 'debug' THEN 'problem_solving'
            WHEN task_type = 'architecture' THEN 'system_design' 
            WHEN task_type = 'coaching' THEN 'knowledge_sharing'
            WHEN task_type = 'knowledge' THEN 'research'
            ELSE 'general_skills'
        END,
        COALESCE((
            SELECT level FROM user_skills 
            WHERE user_id = 'system_learner' 
            AND skill_id = CASE 
                WHEN task_type = 'debug' THEN 'problem_solving'
                WHEN task_type = 'architecture' THEN 'system_design'
                WHEN task_type = 'coaching' THEN 'knowledge_sharing'
                WHEN task_type = 'knowledge' THEN 'research'
                ELSE 'general_skills'
            END
        ), 0) + 1,
        CURRENT_TIMESTAMP
    FROM task_assignments ta
    JOIN tasks t ON ta.task_id = t.id
    WHERE ta.result_status = 'success'
    AND ta.completed_at > datetime('now', '-1 hour')
    GROUP BY t.task_type
    ON CONFLICT(user_id, skill_id) DO UPDATE SET
        level = excluded.level,
        last_updated = excluded.last_updated;
    
    SELECT '✅ تم تحديث ' || changes() || ' مهارة' AS result;
    "
    
    # 4. عرض التقدم
    echo "4. 📊 تقرير التقدم الحالي:"
    sqlite3 "$DB_PATH" "
    SELECT '🎯 المهارات: ' || COUNT(*) || ' مهارة' FROM user_skills;
    SELECT '📚 التعلم: ' || COUNT(*) || ' مهمة تدريب' FROM tasks WHERE source = 'learning_system';
    SELECT '📈 النجاح: ' || ROUND((
        SELECT COUNT(*) FROM task_assignments WHERE result_status = 'success'
    ) * 100.0 / (
        SELECT COUNT(*) FROM task_assignments WHERE result_status IS NOT NULL
    ), 1) || '% معدل نجاح';
    "
    
    # انتظار للدورة التالية
    if [ $cycle -lt $MAX_CYCLES ]; then
        echo "⏳ انتظار $SLEEP_TIME ثانية للتفكير والتخطيط..."
        sleep $SLEEP_TIME
        echo ""
    fi
done

echo "✅ اكتملت دورات التعلم المستمر في: $(date)"
echo ""
echo "🎓 الملخص النهائي للتعلم:"
sqlite3 "$DB_PATH" "
SELECT 'مهارات النظام:' as summary;
SELECT skill_id, level FROM user_skills WHERE user_id = 'system_learner' ORDER BY level DESC;

SELECT 'التدريبات المنشأة:' as summary;  
SELECT COUNT(*) as training_count FROM tasks WHERE source = 'learning_system';

SELECT 'التقدم العام:' as summary;
SELECT 
    (SELECT COUNT(*) FROM tasks WHERE status = 'done') as completed_tasks,
    (SELECT COUNT(*) FROM tasks WHERE status = 'queued') as pending_tasks,
    (SELECT ROUND(AVG(success_rate), 2) FROM agents WHERE total_runs > 0) as avg_success_rate;
"
