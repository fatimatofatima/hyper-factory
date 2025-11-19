#!/bin/bash
echo "🏥 فحص الصحة الشامل..."
echo "======================"

echo "🔍 فحص الموارد:"
echo "💾 ذاكرة حرة: $(free -h | grep Mem | awk '{print $4}')"
echo "💿 مساحة حرة: $(df -h / | tail -1 | awk '{print $4}')"
echo ""

echo "📁 فحص الهيكل:"
mkdir -p reports/ai reports/management reports/diagnostics
echo "✅ هيكل المجلدات جاهز"
echo ""

echo "📋 فحص السكريبتات:"
scripts=("hf_ops_master.sh" "run_basic_with_memory.sh" "hf_run_manager_dashboard.sh")
for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        echo "✅ $script موجود"
    else
        echo "❌ $script غير موجود"
    fi
done
echo ""

echo "✅ فحص الصحة اكتمل"
