#!/bin/bash
# Hyper Factory - Smart Lessons Investigation
# فحص ذكي لمشكلة كشف الدروس في Manager Dashboard

echo "🔍 بدء الفحص الذكي لمشكلة الدروس..."
echo "==========================================="

# 1) فحص الملفات الموجودة فعلياً
echo "📁 1) فحص ملفات الدروس على القرص:"
LESSONS_COUNT=$(find ai/memory/lessons/ -name "*.json" 2>/dev/null | wc -l)
echo "   - عدد ملفات الدروس: $LESSONS_COUNT"
if [ $LESSONS_COUNT -gt 0 ]; then
    echo "   ✅ الملفات موجودة فعلياً"
    echo "   📋 أمثلة من الملفات:"
    find ai/memory/lessons/ -name "*.json" | head -3 | while read file; do
        echo "      - $file ($(stat -c%s "$file") بايت)"
    done
else
    echo "   ❌ لا توجد ملفات دروس!"
fi

echo

# 2) فحص كود Manager Dashboard
echo "🔧 2) فحص كود hf_manager_dashboard.py:"
if [ -f "tools/hf_manager_dashboard.py" ]; then
    echo "   ✅ الملف موجود"
    
    # البحث عن سطور كشف الدروس
    echo "   🔎 البحث عن منطق كشف الدروس:"
    grep -n -A 5 -B 5 "lessons" tools/hf_manager_dashboard.py | head -20
    
    # فحص الدالة المسؤولة عن الدروس
    echo "   🔎 البحث عن دالة الدروس:"
    grep -n "def.*lesson" tools/hf_manager_dashboard.py
    
else
    echo "   ❌ ملف hf_manager_dashboard.py غير موجود!"
fi

echo

# 3) فحص آخر تقرير Manager
echo "📊 3) فحص آخر تقرير Manager:"
LATEST_MANAGER=$(ls -1t reports/management/*_manager_daily_overview.txt 2>/dev/null | head -1)
if [ -n "$LATEST_MANAGER" ]; then
    echo "   📄 آخر تقرير: $LATEST_MANAGER"
    echo "   🔍 فحص قسم الدروس في التقرير:"
    grep -A 10 -B 2 "الدروس المستفادة" "$LATEST_MANAGER" 2>/dev/null || echo "   ❌ قسم الدروس غير موجود في التقرير"
else
    echo "   ❌ لا توجد تقارير Manager!"
fi

echo

# 4) فحص قاعدة المعرفة
echo "🧠 4) فحص قاعدة المعرفة:"
if command -v sqlite3 >/dev/null 2>&1 && [ -f "data/knowledge/knowledge.db" ]; then
    echo "   ✅ قاعدة المعرفة متاحة"
    DB_LESSONS=$(sqlite3 data/knowledge/knowledge.db "SELECT COUNT(*) FROM knowledge_items WHERE item_type='lesson';" 2>/dev/null)
    echo "   - عدد الدروس في DB: $DB_LESSONS"
else
    echo "   ⚠️  قاعدة المعرفة غير متاحة للفحص"
fi

echo

# 5) فحص سكربتات تطبيق الدروس
echo "🔄 5) فحص سكربتات الدروس:"
if [ -f "hf_run_apply_lessons.sh" ]; then
    echo "   ✅ hf_run_apply_lessons.sh موجود"
    # فحص إذا كان السكربت يقرأ من الملفات أم DB فقط
    grep -n "lessons" hf_run_apply_lessons.sh | head -5
else
    echo "   ❌ hf_run_apply_lessons.sh غير موجود"
fi

echo

# 6) تشخيص المشكلة
echo "🎯 6) تشخيص المشكلة الجذرية:"
echo "   📌 المشكلة المحتملة:"
if [ $LESSONS_COUNT -gt 0 ]; then
    echo "   - الملفات موجودة ولكن الكود لا يكتشفها"
    echo "   - السبب المحتمل:"
    echo "     1. المسار خاطئ في الكود"
    echo "     2. نمط الملفات مختلف عما يبحث عنه الكود"
    echo "     3. خطأ في منطق العد/الكشف"
else
    echo "   - لا توجد ملفات دروس على القرص"
    echo "   - الدروس موجودة فقط في قاعدة المعرفة"
fi

echo

# 7) حل مقترح
echo "💡 7) الحل المقترح:"
if [ $LESSONS_COUNT -gt 0 ]; then
    echo "   🔧 إصلاح مسار/نمط البحث في hf_manager_dashboard.py"
    echo "   📝 التأكد من أن الكود يبحث في: ai/memory/lessons/*.json"
else
    echo "   🔧 إنشاء سكربت لتصدير الدروس من DB إلى ملفات"
    echo "   📝 تشغيل: ./hf_run_export_lessons.sh (إذا موجود)"
fi

echo "==========================================="
echo "✅ انتهى الفحص الذكي - جاهز للحل!"
