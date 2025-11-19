#!/bin/bash

echo "🏭 Hyper Factory - Quick Dashboard 🚀"
echo "===================================="
cd /root/hyper-factory

# التشغيل السريع لكل شيء
echo "🔍 فحص النظام..."
./hf_find_all_agents.sh | head -20

echo ""
echo "🏭 تشغيل المصنع..."
./run_basic_with_memory.sh

echo ""
echo "📊 تحديث الإدارة..."
./hf_run_manager_dashboard.sh

echo ""
echo "🧠 إنشاء التقارير..."
./hf_export_ai_context.sh
./hf_export_owner_report.sh

echo ""
echo "📋 التقارير النهائية:"
echo "   📄 المالك: $(ls -1t reports/ai/OWNER_*_owner_report.md 2>/dev/null | head -1)"
echo "   📊 المدير: $(ls -1t reports/management/*_manager_daily_overview.txt 2>/dev/null | head -1)"
echo "   🧠 الذاكرة: $(find ai/memory/ -name "*.json" | wc -l) ملف"

echo "✅ اكتمل التشغيل السريع!"
