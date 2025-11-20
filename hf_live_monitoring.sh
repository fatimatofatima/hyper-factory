#!/bin/bash
echo "📡 نظام المراقبة المستمرة - تحديث كل 30 ثانية"

while true; do
    clear
    echo "🔄 تحديث المراقبة - $(date '+%H:%M:%S')"
    echo "=========================================="
    
    # تحديث القياسات
    python3 /root/hyper-factory/tools/hf_performance_monitor.py
    python3 /root/hyper-factory/tools/hf_unified_dashboard.py
    
    # عرض لوحة التحكم
    cat /root/hyper-factory/reports/dashboard/unified_dashboard.txt
    
    echo ""
    echo "⏳ التحديث القادم خلال 30 ثانية... (Ctrl+C للإيقاف)"
    sleep 0.1
done
