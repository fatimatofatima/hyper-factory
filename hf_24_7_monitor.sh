#!/bin/bash
echo "📊 Hyper Factory – 24/7 Live Monitor"
echo "===================================="
echo ""

while true; do
    clear
    echo "🕒 آخر تحديث: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    
    # حالة الخدمة
    echo "🔧 حالة الخدمة:"
    SERVICE_STATUS=$(sudo systemctl is-active hyper-factory.service)
    if [ "$SERVICE_STATUS" = "active" ]; then
        echo "  ✅ نشطة - PID: $(sudo systemctl show hyper-factory.service --property=MainPID --value)"
    else
        echo "  ❌ غير نشطة"
    fi
    
    # إحصائيات المصنع
    echo ""
    echo "📈 إحصائيات المصنع:"
    if [ -f "data/factory/factory.db" ]; then
        sqlite3 data/factory/factory.db "
        SELECT 
            '🎯 المهام: ' || COUNT(*) as tasks,
            '✅ المكتملة: ' || SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) as done,
            '⏳ في الطابور: ' || SUM(CASE WHEN status='queued' THEN 1 ELSE 0 END) as queued,
            '👥 العمال: ' || (SELECT COUNT(*) FROM agents) as agents,
            '📊 النجاح: ' || ROUND(100.0 * SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) / COUNT(*), 1) || '%' as success_rate
        FROM tasks;
        " | while read line; do
            echo "  $line"
        done
    fi
    
    # آخر السجلات
    echo ""
    echo "📋 آخر السجلات:"
    if sudo journalctl -u hyper-factory.service -n 5 --no-pager 2>/dev/null | grep -v "Started Hyper Factory" | grep -v "Starting Hyper Factory"; then
        sudo journalctl -u hyper-factory.service -n 3 --no-pager 2>/dev/null | tail -n +2
    else
        echo "  🔄 جاري التشغيل..."
    fi
    
    echo ""
    echo "⏳ التحديث خلال 10 ثواني... (Ctrl+C للإيقاف)"
    sleep 0.1
done
