#!/bin/bash
echo "🚀 TURBO MANAGER - NO SLEEP MODE"

while true; do
    echo "🔄 دورة مدير سريعة - $(date '+%H:%M:%S')"
    
    # تشغيل التقييم والأولويات
    ./hf_self_evaluation_system.sh
    ./hf_create_priority_files.sh
    
    # تشغيل المدير
    ./hf_run_manager_engine.sh
    
    # تشغيل المنفذ التلقائي
    ./hf_auto_executor.sh
    
    # لا يوجد sleep هنا!
done
