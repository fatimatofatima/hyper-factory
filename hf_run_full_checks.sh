#!/bin/bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "🏥 Hyper Factory - Full Checks"
echo "=============================="
echo "📍 المسار الحالي: $(pwd)"
echo "⏰ الوقت: $(date)"
echo

echo "1) 🔍 فحص صحة النظام (System Guardian)..."
python3 tools/system_guardian.py
echo

echo "2) 🧪 اختبار قاعدة المعرفة..."
python3 scripts/test_knowledge_fixed.py
echo

echo "3) 🤖 تشغيل Debug Expert Final..."
python3 tools/hf_debug_expert_final.py
echo

echo "✅ جميع الفحوصات اكتملت بنجاح"
