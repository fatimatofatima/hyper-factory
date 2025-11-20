#!/bin/bash
echo "🏭 تشغيل نظام Hyper Factory المتكامل..."

# 1. تشغيل جميع العوامل الأساسية
AGENTS=(
    "debug_expert"
    "system_architect" 
    "knowledge_spider"
    "technical_coach"
    "quality_engine"
    "patterns_engine"
    "temporal_memory"
)

for agent in "${AGENTS[@]}"; do
    if [ -f "./hf_run_${agent}.sh" ]; then
        echo "▶️  تشغيل $agent..."
        ./hf_run_${agent}.sh &
        sleep 0.5
    fi
done

# 2. تشغيل نظام المراقبة
echo "📈 تشغيل نظام المراقبة..."
./hf_24_7_monitor.sh &

# 3. تشغيل المدير التلقائي
echo "🤖 تشغيل المدير التلقائي..."
./hf_factory_manager_loop.sh &

# 4. عرض النتائج
sleep 3
echo ""
echo "🎉 نظام Hyper Factory يعمل بالكامل!"
echo "📊 العوامل النشطة:"
ps aux | grep "hf_run_" | grep -v grep | awk '{print "   ✅ " $11}'
echo ""
echo "🖥️  لوحة التحكم:"
./hf_factory_dashboard.sh
