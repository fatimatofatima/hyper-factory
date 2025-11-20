#!/bin/bash
echo "🚀 وضع التوربو - تشغيل فوري!"

# قائمة العوامل للتشغيل المباشر
AGENTS=("debug_expert" "system_architect" "knowledge_spider" "technical_coach" "quality_engine")

for agent in "${AGENTS[@]}"; do
    if [ -f "./hf_run_${agent}.sh" ]; then
        echo "▶️  تشغيل $agent..."
        ./hf_run_${agent}.sh &
        sleep 0.1
    fi
done

echo "🎯 العوامل النشطة:"
ps aux | grep "hf_run_" | grep -v grep | awk '{print "   ✅ " $11}'

echo "📊 لوحة التحكم السريعة:"
./hf_factory_dashboard.sh
