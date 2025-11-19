#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

REMOTE="${REMOTE:-origin}"
BRANCH="${1:-main}"
MSG="${2:-"chore: sync hyper-factory"}"

echo "🏭 Hyper Factory – Git Sync"
echo "📍 $BASE_DIR"
echo "🔀 Remote: $REMOTE | Branch: $BRANCH"
echo "📝 Message: $MSG"
echo "------------------------------------"

# عرض الحالة
git status -sb || { echo "❌ هذا المجلد ليس git repo"; exit 1; }

# التأكد من وجود الفرع
if ! git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  echo "ℹ️ الفرع $BRANCH غير موجود محليًا، محاولة تتبعه من $REMOTE..."
  git fetch "$REMOTE"
  git checkout -b "$BRANCH" "$REMOTE/$BRANCH"
else
  git checkout "$BRANCH"
fi

# إضافة كل التغييرات (باستثناء ما هو في .gitignore)
echo "➕ git add -A"
git add -A

# محاولة الالتزام
if git diff --cached --quiet; then
  echo "ℹ️ لا توجد تغييرات للالتزام."
else
  echo "✅ git commit -m \"$MSG\""
  git commit -m "$MSG"
fi

# تحديث من الريموت مع rebase
echo "⬇️ git pull --rebase $REMOTE $BRANCH"
git pull --rebase "$REMOTE" "$BRANCH" || {
  echo "⚠️ تعارض في الـ rebase، فضّل حله يدويًا ثم أعد تشغيل السكربت."
  exit 1
}

# دفع التغييرات
echo "⬆️ git push $REMOTE $BRANCH"
git push "$REMOTE" "$BRANCH"

echo "✅ Sync مكتمل بدون رفع أي أسرار (طالما .gitignore مضبوط)."
