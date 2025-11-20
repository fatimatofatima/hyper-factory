#!/bin/bash
echo "📊 لوحة أداء Hyper Factory - تحديث حي"
echo "==========================================="

while true; do
    clear
    
    # بيانات الأداء
    STATS=$(sqlite3 /root/hyper-factory/data/factory/factory.db <<'SQL'
SELECT 
    (SELECT COUNT(*) FROM agents) as agents,
    (SELECT COUNT(*) FROM tasks) as tasks,
    (SELECT COUNT(*) FROM tasks WHERE status='done') as done,
    (SELECT COUNT(*) FROM tasks WHERE status='queued') as queued,
    (SELECT COUNT(*) FROM tasks WHERE status='assigned') as assigned,
    (SELECT AVG(success_rate) FROM agents) as avg_success
SQL
)

    IFS='|' read -r agents tasks done queued assigned avg_success <<< "$STATS"
    
    # حساب النسب
    completion_rate=$((tasks > 0 ? done * 100 / tasks : 0))
    assignment_rate=$((tasks > 0 ? assigned * 100 / tasks : 0))
    
    # عرض النتائج
    echo "🕒 آخر تحديث: $(date '+%H:%M:%S')"
    echo "👥 العوامل النشطة: $agents"
    echo "📊 متوسط النجاح: ${avg_success:-0}%"
    echo ""
    echo "🎯 إجمالي المهام: $tasks"
    echo "✅ مكتملة: $done ($completion_rate%)"
    echo "🔄 قيد التنفيذ: $assigned ($assignment_rate%)"
    echo "⏳ في الانتظار: $queued"
    echo ""
    echo "💡 العوامل الأكثر نشاطاً:"
    sqlite3 /root/hyper-factory/data/factory/factory.db \
    "SELECT id, display_name, total_runs, success_rate 
     FROM agents 
     ORDER BY total_runs DESC 
     LIMIT 5;" | while IFS='|' read id name runs rate; do
        echo "   🟢 $name: $runs تشغيل ($rate% نجاح)"
    done
    
    echo ""
    echo "⏳ التحديث خلال 5 ثواني... (Ctrl+C للإيقاف)"
    sleep 0.1
done
