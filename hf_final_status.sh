#!/bin/bash

echo "🏭 Hyper Factory - Final Status Report 🎯"
echo "========================================"
echo "⏰ $(date)"
echo ""

# حالة Git
echo "📊 حالة الريبو:"
git log --oneline -3
echo ""

# حالة العمال
echo "🤖 حالة العمال:"
./hf_find_all_agents.sh | grep -E "📊|🎉|⚠️" | head -5
echo ""

# التقارير الحديثة
echo "📋 أحدث التقارير:"
find reports/ -name "*.md" -o -name "*.txt" 2>/dev/null | xargs ls -lt 2>/dev/null | head -5
echo ""

# الذاكرة والنظام
echo "🧠 حالة النظام:"
echo "   - التقارير: $(find reports/ -name "*.md" -o -name "*.txt" 2>/dev/null | wc -l)"
echo "   - الذاكرة: $(find ai/memory/ -name "*.json" -o -name "*.txt" 2>/dev/null | wc -l)"
echo "   - السكريبتات: $(find . -name "hf_run_*.sh" -o -name "run_*.sh" 2>/dev/null | wc -l)"
echo ""

echo "🎉 Hyper Factory جاهز للإنتاج!"
echo "📍 GitHub: https://github.com/fatimatofatima/hyper-factory"
echo "🚀 التشغيل: ./hf_quick_dashboard.sh"
