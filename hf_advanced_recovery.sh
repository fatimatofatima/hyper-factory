#!/bin/bash
# استعادة النظام المتقدمة مع معالجة جميع المشاكل

echo "🔄 بدء استعادة النظام المتقدمة..."

# 1. إصلاح الأذونات
find /root/hyper-factory -name "*.sh" -exec chmod +x {} \;

# 2. تشغيل الفحوصات الأساسية
./hf_comprehensive_health_check.sh
./hf_factory_health_check.sh

# 3. تشغيل العوامل الأساسية
./hf_run_system_architect.sh &
./hf_run_debug_expert.sh &
./hf_run_knowledge_spider.sh &

# 4. تشغيل نظام المراقبة
./hf_24_7_monitor.sh &

# 5. تحديث لوحة التحكم
./hf_factory_dashboard.sh

echo "✅ اكتملت استعادة النظام المتقدمة"
