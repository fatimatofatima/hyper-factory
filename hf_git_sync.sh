#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

REMOTE="${REMOTE:-origin}"
BRANCH="${1:-master}"
MSG="${2:-chore: sync hyper-factory"}"

echo "🏭 Hyper Factory – Git Sync"
echo "📍 $BASE_DIR"
echo "🔀 Remote: $REMOTE | Branch: $BRANCH"
echo "📝 Message: $MSG"
echo "------------------------------------"

# تحقق أن المجلد git repo
git status -sb || { echo "❌ هذا المجلد ليس git repo"; exit 1; }

# التأكد من وجود الفرع محليًا
if ! git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  echo "ℹ️ الفرع $BRANCH غير موجود محليًا، محاولة تتبعه من $REMOTE..."
  git fetch "$REMOTE"
  git checkout -b "$BRANCH" "$REMOTE/$BRANCH"
else
  git checkout "$BRANCH"
fi

# إضافة كل التغييرات (مع احترام .gitignore)
echo "➕ git add -A"
git add -A

# لو لا توجد تغييرات staged، لا نعمل commit
if git diff --cached --quiet; then
  echo "ℹ️ لا توجد تغييرات للالتزام (commit)."
else
  echo "✅ git commit -m \"$MSG\""
  git commit -m "$MSG"
fi

# تحديث من الريموت مع rebase
echo "⬇️ git pull --rebase $REMOTE $BRANCH"
if ! git pull --rebase "$REMOTE" "$BRANCH"; then
  echo "⚠️ تعارض في rebase، حلّه يدويًا ثم أعد تشغيل hf_git_sync.sh"
  exit 1
fi

# دفع التغييرات للريموت
echo "⬆️ git push $REMOTE $BRANCH"
git push "$REMOTE" "$BRANCH"

echo "✅ Sync مكتمل بدون رفع أي داتا تشغيلية أو أسرار (طالما .gitignore مضبوط)."
