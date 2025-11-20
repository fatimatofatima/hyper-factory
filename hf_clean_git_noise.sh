#!/usr/bin/env bash
set -Eeuo pipefail

echo "🧹 Hyper Factory - Git Noise Cleanup"
echo "===================================="
echo

# التحقق من وجود ملف $DB_PATH
if git status | grep -q '\$DB_PATH'; then
    echo "🗑️  إزالة ملف \$DB_PATH الشارد..."
    git rm '$DB_PATH' 2>/dev/null || true
    git rm "\$DB_PATH" 2>/dev/null || true
fi

# عرض الملفات التي يمكن تنظيفها
echo "📋 الملفات التي يمكن إضافتها لـ .gitignore:"
git status --porcelain | grep -E "^\?\?" | cut -c4- | head -10

echo
echo "📊 حالة git الحالية:"
git status --short

echo
echo "💡 التوصيات:"
echo "1. ملفات reports/ يتم تجاهلها بالفعل ✓"
echo "2. considerar إضافة ai/memory/ لـ .gitignore"
echo "3. considerar إضافة logs/ لـ .gitignore"

echo
echo "✅ التنظيف جاهز - راجع التغييرات قبل commit!"
