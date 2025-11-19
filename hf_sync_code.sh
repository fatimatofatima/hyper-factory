#!/usr/bin/env bash
# Hyper Factory - Code Sync (server → GitHub)
# مزامنة آمنة للكود فقط، مع حماية فرع main

set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "============================================"
echo "🔄 Hyper Factory – Code Sync (server → GitHub)"
echo "📁 ROOT : $ROOT"
echo "============================================"

# التأكد من فرع master
current_branch=$(git rev-parse --abbrev-ref HEAD)
echo "📌 الفرع الحالي: ${current_branch}"

if [[ "$current_branch" != "master" ]]; then
    echo "❌ المزامنة مسموحة فقط على فرع master"
    echo "↪️ نفّذ أولاً: git checkout master"
    exit 1
fi

# سحب أحدث التغييرات
echo "📥 سحب التحديثات من GitHub..."
git pull origin master

# إضافة الملفات المهمة فقط (بدون البيانات التشغيلية)
echo "📦 إضافة الملفات المهمة..."
git add \
    config/ \
    scripts/ \
    tools/ \
    design/ \
    agents/ \
    apps/ \
    hf_*.sh \
    run_*.sh \
    setup_*.sh \
    README.md \
    .gitignore

# commit التغييرات
echo "💾 حفظ التغييرات..."
git commit -m "HF: sync server code - $(date '+%Y-%m-%d %H:%M')" || echo "⚠️ لا توجد تغييرات جديدة"

# رفع التغييرات
echo "🚀 رفع التغييرات إلى GitHub..."
git push origin master

echo "✅ اكتملت المزامنة بنجاح!"
echo "📊 حالة الريبو:"
git status --short
