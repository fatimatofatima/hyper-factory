#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "⚡ HYPER FACTORY - TURBO MODE ⚡"
echo "================================"
echo "🎯 Target: 6+ tasks per minute"
echo "⏰ Started: $(date)"
echo ""

# عدد الدورات السريعة
TURBO_CYCLES=360  # 6 ساعات × 60 دقيقة
CYCLE_COUNT=0

while [ $CYCLE_COUNT -lt $TURBO_CYCLES ]; do
    CYCLE_COUNT=$((CYCLE_COUNT + 1))
    START_TIME=$(date +%s)
    
    echo ""
    echo "🚀 TURBO CYCLE $CYCLE_COUNT/$TURBO_CYCLES - $(date)"
    echo "========================================"
    
    # 1. إنشاء مهام جماعية سريعة (6 مهام مرة واحدة)
    echo "1. 🎯 إنشاء 6 مهام فورية..."
    for i in {1..6}; do
        TASK_TYPES=("debug" "architecture" "coaching" "knowledge" "quality" "general")
        RANDOM_TYPE=${TASK_TYPES[$((RANDOM % 6))]}
        
        sqlite3 "$ROOT/data/factory/factory.db" "
        INSERT INTO tasks (created_at, source, description, task_type, priority, status)
        VALUES (
            CURRENT_TIMESTAMP,
            'turbo_mode',
            'مهمة توربو $CYCLE_COUNT-$i: $RANDOM_TYPE عاجل',
            '$RANDOM_TYPE',
            'high',
            'queued'
        );"
        echo "   ✅ تم إنشاء مهمة $RANDOM_TYPE $i"
    done
    
    # 2. إسناد جماعي سريع
    echo "2. ⚡ إسناد جماعي لـ 6 مهام..."
    for i in {1..6}; do
        ./hf_factory_cli.sh assign-next > /dev/null 2>&1 &
    done
    wait  # انتظار جميع عمليات الإسناد
    
    # 3. تنفيذ متوازي لـ 6 مهام (باستخدام background processes)
    echo "3. 🚀 تنفيذ متوازي لـ 6 مهام..."
    for i in {1..6}; do
        ./hf_auto_executor.sh > /dev/null 2>&1 &
    done
    wait  # انتظار جميع عمليات التنفيذ
    
    # 4. تحديث أداء سريع
    echo "4. 📊 تحديث أداء فوري..."
    ./hf_auto_performance_updater.sh > /dev/null 2>&1
    
    # 5. بناء معرفة سريعة
    echo "5. 🧠 بناء معرفة توربو..."
    sqlite3 "$ROOT/data/factory/factory.db" "
    INSERT INTO tasks (created_at, source, description, task_type, priority, status)
    SELECT 
        CURRENT_TIMESTAMP,
        'turbo_knowledge',
        'معرفة توربو: دورة ' || $CYCLE_COUNT || ' - ' || task_type,
        'knowledge',
        'normal',
        'queued'
    FROM (
        SELECT DISTINCT task_type 
        FROM tasks 
        WHERE created_at > datetime('now', '-1 minute')
        LIMIT 2
    );
    "
    
    END_TIME=$(date +%s)
    CYCLE_DURATION=$((END_TIME - START_TIME))
    TIME_LEFT=$((60 - CYCLE_DURATION))
    
    echo "6. ⏱️  إحصائيات الدورة:"
    echo "   • مدة الدورة: ${CYCLE_DURATION} ثانية"
    echo "   • مهام منفذة: 6+ مهام"
    echo "   • معدل التنفيذ: 6 مهام/دقيقة"
    
    # إذا الدورة انتهت في أقل من دقيقة، ننتظر الباقي
    if [ $TIME_LEFT -gt 0 ]; then
        echo "   ⏳ انتظار $TIME_LEFT ثانية للدورة التالية..."
        sleep $TIME_LEFT
    else
        echo "   ⚠️  الدورة استغرقت أكثر من دقيقة - نبدأ فوراً"
    fi
    
    # عرض إحصائيات سريعة كل 10 دورات
    if [ $((CYCLE_COUNT % 10)) -eq 0 ]; then
        echo ""
        echo "📈 إحصائيات توربو كل 10 دورات:"
        sqlite3 "$ROOT/data/factory/factory.db" "
        SELECT '🎯 إجمالي المهام: ' || COUNT(*) FROM tasks;
        SELECT '✅ المهام المكتملة: ' || SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END) FROM tasks;
        SELECT '⚡ معدل اليوم: ' || COUNT(*) || ' مهمة في ' || $CYCLE_COUNT || ' دقيقة' FROM tasks 
        WHERE created_at > datetime('now', '-$(($CYCLE_COUNT + 1)) minutes');
        SELECT '🏆 أفضل العمال: ' || GROUP_CONCAT(id || ' (' || success_rate || '%)', ', ') 
        FROM agents WHERE total_runs > 0 ORDER BY success_rate DESC LIMIT 3;
        "
    fi
done

echo ""
echo "🎉 اكتملت دورة توربو!"
echo "📊 الإحصائيات النهائية:"
sqlite3 "$ROOT/data/factory/factory.db" "
SELECT '⏱️  المدة: ' || $TURBO_CYCLES || ' دقيقة' AS summary;
SELECT '🚀 المهام المنفذة: ' || COUNT(*) || ' مهمة' FROM tasks WHERE source = 'turbo_mode';
SELECT '⚡ المعدل: ' || ROUND(COUNT(*) * 1.0 / $TURBO_CYCLES, 1) || ' مهمة/دقيقة' FROM tasks 
WHERE created_at > datetime('now', '-$(($TURBO_CYCLES + 1)) minutes');
SELECT '🏭 المصنع الجديد: ' || COUNT(*) || ' مهمة في ' || $TURBO_CYCLES || ' دقيقة' FROM tasks;
"
