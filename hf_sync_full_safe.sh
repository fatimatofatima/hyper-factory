#!/bin/bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT" 2>/dev/null || {
  echo "❌ لا يمكن الدخول إلى $ROOT"
  exit 1
}

echo "🔄 Hyper Factory – Full Safe Sync (no secrets)"
echo "📍 ROOT = $ROOT"
echo "⏰ $(date)"
echo "============================================"
echo

echo "📊 الحالة الحالية (قبل أي إضافة):"
git status
echo "============================================"
echo

echo "📦 [1/3] إضافة كل الملفات (مع استثناء الأسرار والـ runtime)..."

git add -A . \
  ':!data/knowledge/' \
  ':!ai/memory/' \
  ':!hf_backups/' \
  ':!*.db' \
  ':!*.sqlite' \
  ':!*.env' \
  ':!*secret*' \
  ':!*token*' \
  ':!*.zst' \
  ':!*.tar' \
  ':!*.tar.gz' \
  ':!*.log' \
  ':!__pycache__/' \
  ':!*.pyc' \
  ':!*venv*' \
  ':!*.pid' \
  ':!*.sock'

echo
echo "📊 الحالة بعد git add (للمراجعة):"
git status
echo "============================================"
echo
read -r -p "✅ راجع القائمة أعلاه. اضغط Enter للمتابعة بالـ commit + push أو Ctrl+C للإلغاء... " _

echo
echo "📝 [2/3] إنشاء commit (إن وُجدت تغييرات)..."
COMMIT_MSG="HF: full safe sync (no secrets) - $(date +'%Y-%m-%d %H:%M')"
if git commit -m "$COMMIT_MSG"; then
  echo "✅ تم إنشاء commit: $COMMIT_MSG"
else
  echo "⚠️ لا توجد تغييرات لعمل commit."
fi

echo
echo "🚀 [3/3] دفع التغييرات إلى origin/master..."
if git push origin master; then
  echo "✅ تم رفع التغييرات بنجاح إلى GitHub."
else
  echo "⚠️ حصلت مشكلة أثناء git push – تأكد من الاتصال/الصلاحيات."
fi

echo
echo "🎯 Full Safe Sync انتهى."
