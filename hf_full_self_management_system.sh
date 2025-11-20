#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "🤖 Hyper Factory – Full Self Management System"
echo "=============================================="
echo "⏰ بدء الإدارة الذاتية الكاملة: $(date)"
echo ""

# عدد الدورات (تشغيل مستمر)
CYCLE=0
while true; do
    CYCLE=$((CYCLE + 1))
    echo ""
    echo "🔄 الدورة $CYCLE - $(date)"
    echo "==============================="
    
    # 1. التشغيل الأساسي للمصنع
    echo "1. 🏭 التشغيل الأساسي للمصنع..."
    ./hf_full_auto_cycle.sh
    
    # 2. البحث الذاتي وجمع المعرفة
    echo "2. 🔍 البحث الذاتي وجمع المعرفة..."
    ./hf_auto_researcher.sh
    
    # 3. النظام التدريبي الذاتي
    echo "3. 🎓 النظام التدريبي الذاتي..."
    ./hf_self_training_system.sh
    
    # 4. نظام التقييم الذاتي
    echo "4. 📊 نظام التقييم الذاتي..."
    ./hf_self_evaluation_system.sh
    
    # 5. بناء المعرفة المستمر
    echo "5. 🧠 بناء المعرفة المستمر..."
    ./hf_knowledge_continuous_builder.sh
    
    # 6. مراقبة الجودة الذاتية
    echo "6. 🎯 مراقبة الجودة الذاتية..."
    ./hf_quality_continuous_monitor.sh
    
    # 7. عائلة السبايدرز للمعرفة
    echo "7. 🕷️ عائلة السبايدرز للمعرفة..."
    ./hf_spiders_family.sh
    
    # 8. تقرير الحالة الذاتي
    echo "8. 📈 تقرير الحالة الذاتي الشامل:"
    sqlite3 "$ROOT/data/factory/factory.db" "
    SELECT '🤖 النظام: ' || COUNT(*) || ' عامل نشط' FROM agents WHERE total_runs > 0;
    SELECT '🎯 المهام: ' || COUNT(*) || ' مهمة في النظام' FROM tasks;
    SELECT '✅ المكتمل: ' || SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END) || ' مهمة' FROM tasks;
    SELECT '🧠 المعرفة: ' || COUNT(*) || ' مهمة معرفة' FROM tasks WHERE task_type = 'knowledge';
    SELECT '🎓 التدريب: ' || COUNT(*) || ' مهمة تدريب' FROM tasks WHERE task_type = 'coaching';
    SELECT '📊 التقييمات: ' || COUNT(*) || ' تقييم حديث' FROM performance_evaluations WHERE evaluated_at > datetime('now', '-1 day');
    SELECT '⭐ متوسط الأداء: ' || ROUND(AVG(success_rate), 1) || '%' FROM agents WHERE total_runs > 0;
    SELECT '📈 التطور: ' || ROUND((SELECT AVG(current_level) FROM agent_skills), 1) || '% متوسط المهارات';
    "
    
    # 9. انتظار للدورة التالية (5 دقائق)
    echo ""
    echo "⏳ انتظار 5 دقائق للدورة التالية..."
    echo "💡 النظام يستمر في التعلم والتطوير ذاتياً..."
    sleep 0.1  # 5 دقائق
done

echo "✅ الإدارة الذاتية الكاملة تعمل الآن!"
