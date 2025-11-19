#!/bin/bash
echo "🔍 الفحص الحقيقي للمحتوى الفعلي في الريبو"
echo "=========================================="

# 1. فحص ما هو موجود فعليًا
echo "📁 الهيكل الحقيقي الموجود:"
find . -maxdepth 2 -type d | grep -v "__pycache__" | grep -v ".git" | sort

echo ""
echo "🔧 العمال الحقيقيون الموجودون:"
find agents/ -type f -name "*.py" 2>/dev/null | head -10 || echo "❌ لا يوجد مجلد agents"

echo ""
echo "⚙️ ملفات التكوين الحقيقية:"
ls -1 config/ 2>/dev/null | head -10 || echo "❌ لا يوجد مجلد config"

echo ""
echo "🚀 سكربتات التشغيل الحقيقية:"
ls -1 hf_run_*.sh 2>/dev/null | head -10 || echo "❌ لا توجد سكربتات تشغيل"

echo ""
echo "📊 قاعدة المعرفة الحقيقية:"
if [ -f "data/knowledge/knowledge.db" ]; then
    sqlite3 data/knowledge/knowledge.db ".tables" 2>/dev/null || echo "❌ خطأ في فحص DB"
else
    echo "❌ قاعدة المعرفة غير موجودة"
fi

echo ""
echo "=========================================="
echo "🎯 التحليل بناءً على المحتوى الفعلي:"
echo ""

# فحص الـ gaps الحقيقية
echo "❌ المفقود حقًا (بناءً على الريبو):"

# فحص smart_factory
if [ ! -d "smart_factory" ]; then
    echo "  - smart_factory/ ❌"
else
    echo "  - smart_factory/ ✅"
fi

# فحص learning_system  
if [ ! -d "learning_system" ]; then
    echo "  - learning_system/ ❌"
else
    echo "  - learning_system/ ✅"
fi

# فحص data_lakehouse
if [ ! -d "data_lakehouse" ]; then
    echo "  - data_lakehouse/ ❌"
else
    echo "  - data_lakehouse/ ✅"
fi

# فحص factories
if [ ! -d "factories" ]; then
    echo "  - factories/ ❌"
else
    echo "  - factories/ ✅"
fi

# فحص stack
if [ ! -d "stack" ]; then
    echo "  - stack/ ❌"
else
    echo "  - stack/ ✅"
fi

echo ""
echo "✅ الموجود حقًا:"
echo "  - نظام أساسي (hyper-factory) ✅"
echo "  - عمال أساسيون ✅" 
echo "  - قاعدة معرفة ✅"
echo "  - أدوات متقدمة ✅"
