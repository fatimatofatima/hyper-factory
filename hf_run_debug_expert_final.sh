#!/bin/bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "🤖 Hyper Factory - Debug Expert Final"
echo "====================================="
echo "📍 المسار الحالي: $(pwd)"
echo "⏰ الوقت: $(date)"
echo

# تشغيل العامل النهائي
python3 tools/hf_debug_expert_final.py

echo
echo "📂 ملفات الذاكرة المرتبطة:"
if [ -f ai/memory/debug_cases.json ]; then
    echo "   ✅ ai/memory/debug_cases.json"
fi

if [ -f ai/memory/debug_expert_performance.json ]; then
    echo "   ✅ ai/memory/debug_expert_performance.json"
fi

if [ -f ai/memory/debug_report.txt ]; then
    echo
    echo "📄 معاينة من debug_report.txt (آخر 20 سطر):"
    tail -20 ai/memory/debug_report.txt || true
fi

echo
echo "✅ Debug Expert Final اكتمل بنجاح"
