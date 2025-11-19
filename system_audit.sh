#!/bin/bash

echo "🔍 بدء الفحص الشامل للنظام الحالي..."
echo "=========================================="

# 1. فحص البنية التحتية للبيانات
echo "📊 1. فحص بنية البيانات..."
if [ -d "data" ]; then
    echo "✅ مجلد data موجود"
    ls -la data/
else
    echo "❌ مجلد data غير موجود"
fi

echo "---"
echo "🔍 فحص zones البيانات:"
for zone in inbox raw processed semantic serving; do
    if [ -d "data/$zone" ]; then
        count=$(find data/$zone -type f | wc -l)
        echo "✅ $zone: $count ملف"
    else
        echo "❌ $zone: غير موجود"
    fi
done

# 2. فحص نظام العمال الحالي
echo ""
echo "👷 2. فحص نظام العمال الحالي..."
if [ -d "workers" ] || [ -f "workers" ]; then
    echo "✅ مجلد/ملف workers موجود"
    find . -name "*worker*" -o -name "*agent*" | head -10
else
    echo "❌ لا يوجد مجلد workers"
fi

# 3. فحص قاعدة المعرفة
echo ""
echo "🧠 3. فحص قاعدة المعرفة..."
if [ -f "data/knowledge/knowledge.db" ]; then
    echo "✅ قاعدة المعرفة موجودة"
    sqlite3 data/knowledge/knowledge.db "SELECT name FROM sqlite_master WHERE type='table';" 2>/dev/null || echo "❌ خطأ في فحص الجداول"
else
    echo "❌ قاعدة المعرفة غير موجودة"
fi

# 4. فحص نظام التقارير
echo ""
echo "📈 4. فحص نظام التقارير..."
if [ -d "reports" ]; then
    echo "✅ مجلد reports موجود"
    find reports -name "*.json" -o -name "*.md" | head -5
else
    echo "❌ لا يوجد مجلد reports"
fi

# 5. فحص الـ AI والعوامل الذكية
echo ""
echo "🤖 5. فحص مكونات الذكاء الاصطناعي..."
find . -type d -name "ai" -o -name "agents" -o -name "smart*" | head -10

# 6. فحص التكاملات
echo ""
echo "🔗 6. فحص أنظمة التكامل..."
find . -type d -name "integration*" -o -name "*hub*" | head -10

# 7. فحص إعدادات النظام
echo ""
echo "⚙️ 7. فحص إعدادات النظام..."
find . -name "*.yaml" -o -name "*.yml" -o -name "*.json" | grep -E "(config|setting)" | head -10

# 8. فحص السكربتات التشغيلية
echo ""
echo "🚀 8. فحص السكربتات التشغيلية..."
find . -name "*.sh" -type f | head -10

# 9. فحص قاعدة البيانات التفصيلي
echo ""
echo "🗃️ 9. فحص قاعدة المعرفة التفصيلي..."
if [ -f "data/knowledge/knowledge.db" ]; then
    echo "📊 تحليل جداول قاعدة المعرفة:"
    sqlite3 data/knowledge/knowledge.db ".tables" 2>/dev/null
    
    echo ""
    echo "📈 إحصائيات المحتوى:"
    sqlite3 data/knowledge/knowledge.db "SELECT 'web_content: ' || COUNT(*) FROM web_content;" 2>/dev/null
    sqlite3 data/knowledge/knowledge.db "SELECT 'lessons: ' || COUNT(*) FROM lessons;" 2>/dev/null
    sqlite3 data/knowledge/knowledge.db "SELECT 'categories: ' || COUNT(DISTINCT category) FROM web_content;" 2>/dev/null
else
    echo "❌ قاعدة المعرفة غير متاحة للفحص"
fi

# 10. فحص النظام الرئيسي
echo ""
echo "🏭 10. فحص النظام الرئيسي..."
if [ -f "hf_master_system.py" ]; then
    echo "✅ النظام الرئيسي موجود"
    python3 -c "
import ast
with open('hf_master_system.py', 'r') as f:
    tree = ast.parse(f.read())
classes = [node.name for node in ast.walk(tree) if isinstance(node, ast.ClassDef)]
functions = [node.name for node in ast.walk(tree) if isinstance(node, ast.FunctionDef)]
print(f'📦 الصفوف: {classes}')
print(f'🔧 الدوال: {functions[:10]}')
" 2>/dev/null || echo "❌ خطأ في تحليل الكود"
else
    echo "❌ النظام الرئيسي غير موجود"
fi

echo ""
echo "=========================================="
echo "🔍 الفحص اكتمل!"
