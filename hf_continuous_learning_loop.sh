#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

MAX_CYCLES=${1:-5}  # عدد دورات التعلم
SLEEP_TIME=${2:-45} # وقت الانتظار بين الدورات

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
    
    # 2. تحديث المهارات بناءً على الأداء
    echo "2. 📈 تحديث المهارات التلقائي..."
    ./hf_auto_skills_updater.sh
    
    # 3. إنشاء مهام تدريبية جديدة
    echo "3. 🎓 إنشاء تدريبات جديدة..."
    ./hf_auto_training_generator.sh
    
    # 4. بناء معرفة جديدة
    echo "4. 🧠 بناء المعرفة..."
    ./hf_knowledge_builder.sh
    
    # 5. تحديث الأداء
    echo "5. 📊 تحديث أداء العمال..."
    ./hf_auto_performance_updater.sh
    
    # عرض التقدم
    echo "6. 📋 تقرير التقدم:"
    sqlite3 "$DB_PATH" "
    -- تقرير المهارات
    SELECT '🎯 المهارات: ' || COUNT(*) || ' مهارة، أعلى مستوى: ' || MAX(level) 
    FROM user_skills 
    WHERE user_id = 'system_user';
    
    -- تقرير المهام
    SELECT '📊 المهام: ' || COUNT(*) || ' مهمة، ' || 
           SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END) || ' مكتملة'
    FROM tasks;
    
    -- تقرير المعرفة
    SELECT '🧠 المعرفة: ' || COUNT(*) || ' مهمة معرفة قيد التنفيذ'
    FROM tasks 
    WHERE task_type = 'knowledge' AND status IN ('queued', 'assigned');
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
echo "🎯 الملخص النهائي:"
./hf_factory_dashboard.sh
