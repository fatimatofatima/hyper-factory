#!/usr/bin/env bash
set -euo pipefail

echo "⏰ السيدر الرئيسي - تنسيق العمل الكامل"
echo "======================================"

# 1. فحص الحالة اليومية
daily_health_check() {
    echo "🏥 فحص صحة النظام..."
    ./hf_master_dashboard.sh --quick
}

# 2. تشغيل العوامل حسب الجدول
run_scheduled_agents() {
    echo "🤖 تشغيل العوامل المقررة..."
    
    # الوقت الحالي
    current_hour=$(date +%H)
    current_day=$(date +%u)  # 1-7 (الاثنين-الأحد)
    
    case "$current_hour" in
        "09") 
            echo "🕘 9:00 ص - تشغيل التعلم الآلي"
            ./scripts/auto_learning_engine.sh
            ;;
        "11")
            echo "🕚 11:00 ص - مراقبة الجودة"  
            ./scripts/quality_auto_monitor.sh
            ;;
        "14")
            echo "🕑 2:00 م - تحديث المعرفة"
            ./hf_run_knowledge_spider.sh --auto
            ;;
        "16") 
            echo "🕓 4:00 م - تدريب العوامل"
            ./scripts/auto_training_system.sh
            ;;
    esac
}

# 3. معالجة الطلبات الواردة
process_incoming_requests() {
    echo "📨 معالجة الطلبات الواردة..."
    
    # فحص إذا كان هناك طلبات جديدة
    if [[ -f "data/inbox/new_requests.json" ]]; then
        python3 -c "
import json

with open('data/inbox/new_requests.json', 'r') as f:
    requests = json.load(f)

for req in requests:
    message = req['message']
    user = req['user']
    
    # التوجيه الذكي
    if 'error' in message.lower() or 'bug' in message.lower():
        agent = 'debug_expert'
    elif 'مشروع' in message or 'تصميم' in message:
        agent = 'system_architect' 
    elif 'تعلم' in message or 'تدريب' in message:
        agent = 'technical_coach'
    else:
        agent = 'debug_expert'  # افتراضي
        
    print(f'🔀 توجيه طلب من {user} إلى {agent}')
    
    # معالجة الطلب
    import subprocess
    subprocess.run(['./hf_run_' + agent + '.sh', message])
    
    # نقل إلى الأرشيف
    with open('data/inbox/processed_requests.json', 'a') as f:
        json.dump(req, f, ensure_ascii=False)
        f.write('\n')

print('✅ تم معالجة الطلبات الواردة')
"
        # حذف الطلبات المعالجة
        rm -f "data/inbox/new_requests.json"
    else
        echo "ℹ️ لا توجد طلبات جديدة"
    fi
}

# 4. توليد التقارير التلقائية
generate_auto_reports() {
    echo "📊 توليد التقارير التلقائية..."
    
    # تقرير الأداء اليومي
    ./hf_run_manager_dashboard.sh --auto
    
    # تقرير المالك
    ./hf_ops_master.sh --quick
    
    echo "✅ تم توليد التقارير التلقائية"
}

# 5. الصيانة التلقائية
auto_maintenance() {
    echo "🔧 الصيانة التلقائية..."
    
    # تنظيف الملفات المؤقتة
    find /tmp -name "hyper_factory_*" -mtime +1 -delete 2>/dev/null || true
    
    # تدوير السجلات
    if [[ -f "logs/system.log" ]] && [[ $(wc -l < "logs/system.log") -gt 1000 ]]; then
        mv "logs/system.log" "logs/system.log.old"
        touch "logs/system.log"
    fi
    
    echo "✅ تمت الصيانة التلقائية"
}

main() {
    echo "🚀 بدء دورة السيدر الرئيسي..."
    daily_health_check
    run_scheduled_agents  
    process_incoming_requests
    generate_auto_reports
    auto_maintenance
    echo "🎉 اكتملت دورة السيدر الرئيسي!"
}

main "$@"
