#!/bin/bash
echo "📋 عرض التقارير النهائية..."
echo "=========================="

echo "📁 هيكل التقارير:"
find reports -type f -name "*.md" -o -name "*.txt" | head -10

echo ""
echo "📊 ملخص التقارير:"
echo "- تقارير AI: $(find reports/ai -type f | wc -l)"
echo "- تقارير الإدارة: $(find reports/management -type f | wc -l)"
echo "- تقارير التشخيص: $(find reports/diagnostics -type f | wc -l)"

echo ""
echo "✅ جميع التقارير جاهزة"
