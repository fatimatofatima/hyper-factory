#!/bin/bash
echo "🔄 نظام التحسين في الوقت الحقيقي..."

while true; do
    # تحليل الأداء الحالي
    PERFORMANCE_DATA=$(sqlite3 /root/hyper-factory/data/factory/factory.db \
    "SELECT 
        COUNT(*) as total_tasks,
        SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) as completed_tasks,
        SUM(CASE WHEN status='queued' THEN 1 ELSE 0 END) as queued_tasks,
        COUNT(DISTINCT agent_id) as active_agents
     FROM tasks;")
    
    IFS='|' read -r total completed queued active <<< "$PERFORMANCE_DATA"
    
    # حساب معدل الإنجاز
    if [ "$total" -gt 0 ]; then
        completion_rate=$((completed * 100 / total))
    else
        completion_rate=0
    fi
    
    # التحسين التلقائي بناءً على الأداء
    if [ "$completion_rate" -lt 30 ]; then
        echo "📉 أداء منخفض ($completion_rate%) - زيادة العوامل..."
        ./hf_run_debug_expert.sh &
        ./hf_run_knowledge_spider.sh &
    fi
    
    if [ "$queued" -gt 100 ]; then
        echo "📥 طابور كبير ($queued مهمة) - تسريع المعالجة..."
        for i in {1..3}; do
            ./hf_run_system_architect.sh &
            ./hf_run_technical_coach.sh &
        done
    fi
    
    # تحديث التعلم المستمر
    if [ $((RANDOM % 10)) -eq 0 ]; then
        echo "🧠 تحديث معرفة تلقائي..."
        ./hf_knowledge_builder.sh &
    fi
    
    echo "📊 الحالة: $completed/$total مكتملة ($completion_rate%) | $active عامل نشط | $queued في الطابور"
    sleep 30
done
