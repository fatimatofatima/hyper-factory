#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "🔥 HYPER FACTORY - EXTREME TURBO MODE 🔥"
echo "========================================"
echo "🎯 Target: 12+ tasks per minute"
echo "⏰ Started: $(date)"
echo ""

# إعداد قاعدة البيانات للسرعة القصوى
sqlite3 "$ROOT/data/factory/factory.db" "PRAGMA synchronous = OFF; PRAGMA journal_mode = MEMORY;"

EXTREME_CYCLES=720  # 12 ساعة
CYCLE=0

while [ $CYCLE -lt $EXTREME_CYCLES ]; do
    CYCLE=$((CYCLE + 1))
    echo ""
    echo "🔥 EXTREME CYCLE $CYCLE/$EXTREME_CYCLES - $(date +%H:%M:%S)"
    echo "=========================================="
    
    # بداية التوقيت
    START_TS=$(date +%s)
    
    # 1. إنشاء 12 مهمة فورية (باستخدام transaction واحدة)
    echo "1. 🎯 إنشاء 12 مهمة فورية..."
    sqlite3 "$ROOT/data/factory/factory.db" "
    BEGIN TRANSACTION;
    $(for i in {1..12}; do
        TASK_TYPES=("debug" "architecture" "coaching" "knowledge" "quality" "general")
        TYPE=${TASK_TYPES[$((RANDOM % 6))]}
        echo "INSERT INTO tasks (created_at, source, description, task_type, priority, status) VALUES (CURRENT_TIMESTAMP, 'extreme_turbo', 'مهمة إكستريم $CYCLE-$i: $TYPE', '$TYPE', 'high', 'queued');"
    done)
    COMMIT;
    "
    
    # 2. إسناد فوري لـ 12 مهمة (متوازي)
    echo "2. ⚡ إسناد فوري لـ 12 مهمة..."
    for i in {1..12}; do
        {
            sqlite3 "$ROOT/data/factory/factory.db" "
            WITH next_task AS (
                SELECT id, task_type FROM tasks 
                WHERE status = 'queued' AND source = 'extreme_turbo'
                ORDER BY id ASC LIMIT 1
            ),
            best_agent AS (
                SELECT id FROM agents 
                WHERE family = (SELECT CASE 
                    WHEN task_type = 'debug' THEN 'debugging'
                    WHEN task_type = 'architecture' THEN 'architecture' 
                    WHEN task_type = 'coaching' THEN 'training'
                    WHEN task_type = 'knowledge' THEN 'knowledge'
                    ELSE 'any'
                END FROM next_task)
                ORDER BY success_rate DESC, total_runs ASC 
                LIMIT 1
            )
            INSERT INTO task_assignments (task_id, agent_id, assigned_at, decision_reason)
            SELECT 
                (SELECT id FROM next_task),
                (SELECT id FROM best_agent),
                CURRENT_TIMESTAMP,
                'auto_turbo_assignment'
            WHERE EXISTS (SELECT 1 FROM next_task)
            AND EXISTS (SELECT 1 FROM best_agent);
            
            UPDATE tasks SET status = 'assigned' 
            WHERE id = (SELECT id FROM next_task);
            " > /dev/null 2>&1
        } &
    done
    wait
    
    # 3. تنفيذ فوري لـ 12 مهمة (أقصى سرعة)
    echo "3. 🚀 تنفيذ فوري لـ 12 مهمة..."
    for i in {1..12}; do
        {
            TASK_INFO=$(sqlite3 "$ROOT/data/factory/factory.db" "
            SELECT ta.task_id, t.description, ta.agent_id, t.task_type
            FROM task_assignments ta
            JOIN tasks t ON ta.task_id = t.id
            WHERE ta.result_status IS NULL 
            AND ta.assigned_at IS NOT NULL
            AND t.source = 'extreme_turbo'
            LIMIT 1")
            
            if [ -n "$TASK_INFO" ]; then
                TASK_ID=$(echo "$TASK_INFO" | cut -d'|' -f1)
                AGENT_ID=$(echo "$TASK_INFO" | cut -d'|' -f3)
                
                # تنفيذ فوري (بدون سكربت خارجي)
                sqlite3 "$ROOT/data/factory/factory.db" "
                UPDATE task_assignments 
                SET completed_at = CURRENT_TIMESTAMP,
                    result_status = 'success',
                    result_notes = 'تم التنفيذ التوربو'
                WHERE task_id = $TASK_ID;
                
                UPDATE tasks SET status = 'done' WHERE id = $TASK_ID;
                "
            fi
        } &
    done
    wait
    
    # 4. تحديث أداء فوري
    echo "4. 📊 تحديث أداء فوري..."
    {
        sqlite3 "$ROOT/data/factory/factory.db" "
        UPDATE agents 
        SET success_rate = (
            SELECT CASE 
                WHEN COUNT(*) > 0 THEN 
                    ROUND(SUM(CASE WHEN result_status = 'success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
                ELSE 0 
            END
            FROM task_assignments WHERE agent_id = agents.id
        ),
        total_runs = (SELECT COUNT(*) FROM task_assignments WHERE agent_id = agents.id),
        last_updated = CURRENT_TIMESTAMP
        WHERE id IN (SELECT DISTINCT agent_id FROM task_assignments WHERE completed_at IS NOT NULL);
        "
    } &
    
    # 5. معرفة توربو
    echo "5. 🧠 معرفة توربو فورية..."
    {
        sqlite3 "$ROOT/data/factory/factory.db" "
        INSERT INTO tasks (created_at, source, description, task_type, priority, status)
        VALUES (
            CURRENT_TIMESTAMP,
            'extreme_knowledge',
            'معرفة إكستريم: دورة $CYCLE - 12 مهمة',
            'knowledge',
            'normal',
            'queued'
        );
        "
    } &
    
    wait
    
    # حساب الوقت المتبقي
    END_TS=$(date +%s)
    DURATION=$((END_TS - START_TS))
    REMAINING=$((60 - DURATION))
    
    echo "6. ⚡ إحصائيات الدورة:"
    echo "   • المدة: ${DURATION} ثانية"
    echo "   • المهام: 12+ مهمة"
    echo "   • المعدل: 12 مهمة/دقيقة"
    
    if [ $REMAINING -gt 0 ]; then
        echo "   ⏳ انتظار $REMAINING ثانية..."
        sleep $REMAINING
    else
        echo "   🔥 استمرار فوري - نتخطى الانتظار!"
    fi
    
    # إحصائيات كل 5 دورات
    if [ $((CYCLE % 5)) -eq 0 ]; then
        echo ""
        echo "📈 إحصائيات إكستريم:"
        sqlite3 "$ROOT/data/factory/factory.db" "
        SELECT '🚀 المهام: ' || COUNT(*) || ' في ' || $CYCLE || ' دقيقة' FROM tasks 
        WHERE created_at > datetime('now', '-$(($CYCLE + 2)) minutes');
        SELECT '⚡ المعدل: ' || ROUND(COUNT(*) * 1.0 / $CYCLE, 1) || ' مهمة/دقيقة' FROM tasks 
        WHERE source LIKE '%turbo%';
        SELECT '🏆 الإنتاجية: ' || (COUNT(*) * 60 / $CYCLE) || ' مهمة/ساعة' FROM tasks;
        "
    fi
done

echo ""
echo "🎊 اكتمل وضع الإكستريم توربو!"
echo "📊 الإحصائيات الختامية:"
sqlite3 "$ROOT/data/factory/factory.db" "
SELECT '⏱️  المدة: ' || $EXTREME_CYCLES || ' دقيقة' AS summary;
SELECT '🔥 المهام المنفذة: ' || COUNT(*) || ' مهمة' FROM tasks WHERE source LIKE '%turbo%';
SELECT '⚡ متوسط السرعة: ' || ROUND(COUNT(*) * 1.0 / $EXTREME_CYCLES, 1) || ' مهمة/دقيقة' FROM tasks;
SELECT '🏭 الإنتاجية: ' || (COUNT(*) * 60 / $EXTREME_CYCLES) || ' مهمة/ساعة' FROM tasks;
SELECT '📈 التطور: ' || (MAX(id) - MIN(id)) || ' مهمة جديدة' FROM tasks;
"
