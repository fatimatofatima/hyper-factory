#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

MAX_CYCLES=${1:-999}  # تشغيل مستمر
SLEEP_TIME=${2:-120}  # دقيقتين بين الدورات

echo "🔄 Hyper Factory – Continuous Learning System"
echo "=============================================="
echo "⏰ بدء التشغيل المستمر: $(date)"
echo "🎯 عدد الدورات: $MAX_CYCLES (مستمر)"
echo "⏱️  وقت التفكير: $SLEEP_TIME ثانية"
echo ""

CYCLE_COUNT=0
while [ $CYCLE_COUNT -lt $MAX_CYCLES ]; do
    CYCLE_COUNT=$((CYCLE_COUNT + 1))
    
    echo ""
    echo "🔄 الدورة $CYCLE_COUNT - $(date)"
    echo "==============================="
    
    # 1. التشغيل الأساسي
    echo "1. 🏭 التشغيل الأساسي للمصنع..."
    ./hf_full_auto_cycle.sh
    
    # 2. بناء المعرفة المستمر
    echo "2. 🧠 بناء المعرفة المستمر..."
    ./hf_knowledge_continuous_builder.sh
    
    # 3. توليد التدريبات المستمر
    echo "3. 🎓 توليد التدريبات والاختبارات..."
    ./hf_training_continuous_generator.sh
    
    # 4. مراقبة الجودة المستمرة
    echo "4. 🎯 مراقبة الجودة المستمرة..."
    ./hf_quality_continuous_monitor.sh
    
    # 5. عائلة السبايدرز للمعرفة
    echo "5. 🕷️ تشغيل عائلة السبايدرز..."
    ./hf_spiders_family.sh
    
    # 6. عرض التقدم
    echo "6. 📊 تقرير التقدم المستمر:"
    sqlite3 "$ROOT/data/factory/factory.db" "
    SELECT '🎯 المهام: ' || COUNT(*) || ' مهمة' FROM tasks;
    SELECT '✅ المكتمل: ' || SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END) || ' مهمة' FROM tasks;
    SELECT '🧠 المعرفة: ' || COUNT(*) || ' مهمة معرفة' FROM tasks WHERE task_type = 'knowledge';
    SELECT '🎓 التدريب: ' || COUNT(*) || ' مهمة تدريب' FROM tasks WHERE task_type = 'coaching';
    SELECT '🎯 الجودة: ' || COUNT(*) || ' مهمة جودة' FROM tasks WHERE task_type = 'quality';
    SELECT '📈 الأداء: ' || ROUND(AVG(success_rate), 1) || '% معدل نجاح' FROM agents WHERE total_runs > 0;
    "
    
    # 7. انتظار للدورة التالية
    echo "⏳ انتظار $SLEEP_TIME ثانية للدورة التالية..."
    sleep $SLEEP_TIME
done

echo "✅ اكتمل التشغيل المستمر في: $(date)"
