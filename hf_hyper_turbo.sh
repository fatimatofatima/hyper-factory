#!/bin/bash
echo "🔥 تشغيل وضع الضغط العالي - إنتاجية قصوى!"

# 1. تنظيف وتهيئة سريعة
echo "🧹 تنظيف النظام..."
rm -f /root/hyper-factory/logs/factory/*.log
rm -f /root/hyper-factory/data/factory/factory.db-wal
rm -f /root/hyper-factory/data/factory/factory.db-shm

# 2. تشغيل العوامل الأساسية بضغط عالي
echo "🚀 تشغيل العوامل الأساسية بضغط 10x..."
for i in {1..3}; do
    ./hf_run_debug_expert.sh &
    ./hf_run_system_architect.sh &
    ./hf_run_knowledge_spider.sh &
    ./hf_run_technical_coach.sh &
    ./hf_run_quality_engine.sh &
    sleep 0.2
done

# 3. توليد مهام سريعة
echo "🎯 توليد 50 مهمة فورية..."
cat > /tmp/quick_tasks.sql <<'SQL'
INSERT INTO tasks (created_at, source, description, task_type, type, family, priority, status) 
VALUES 
$(for i in {1..50}; do
  echo "(datetime('now'), 'auto', 'مهمة سريعة $i للتدريب', 'debugging', 'training', 'learning', 'high', 'queued'),"
done | sed '$ s/,$//')
SQL

sqlite3 /root/hyper-factory/data/factory/factory.db < /tmp/quick_tasks.sql

# 4. تشغيل محركات التعلم السريع
echo "🧠 تشغيل محركات التعلم المتسارع..."
./hf_run_patterns_engine.sh &
./hf_run_temporal_memory.sh &
./hf_knowledge_builder.sh &

# 5. نظام المراقبة السريع
echo "📊 تشغيل مراقبة الأداء..."
./hf_24_7_monitor.sh &

# 6. عرض النتائج السريعة
sleep 3
echo ""
echo "🎉 نظام الضغط العالي يعمل!"
echo "📈 إحصائيات فورية:"
sqlite3 /root/hyper-factory/data/factory/factory.db "SELECT status, COUNT(*) FROM tasks GROUP BY status;"
echo ""
echo "👥 العوامل النشطة:"
ps aux | grep "hf_run_" | grep -v grep | wc -l
echo ""
echo "🚀 لوحة التحكم السريعة:"
./hf_factory_dashboard.sh
