#!/usr/bin/env bash
# update_and_sync.sh
# 1) يضيف sync_repo.sh للـ Git لو متغير
# 2) يعمل commit برسالة فيها التوقيت
# 3) يشغّل ./sync_repo.sh

set -euo pipefail

ROOT="/root/hyper-factory"

echo "📁 الدخول إلى: $ROOT"
cd "$ROOT"

echo "📦 فحص sync_repo.sh ..."
if git diff --quiet sync_repo.sh 2>/dev/null; then
  echo "ℹ️ لا توجد تغييرات في sync_repo.sh (تخطي الـ commit)"
else
  echo "✅ إضافة sync_repo.sh إلى الـ staging..."
  git add sync_repo.sh
  COMMIT_MSG="Update sync_repo.sh: $(date +'%Y-%m-%d %H:%M:%S')"
  echo "📝 إنشاء commit: $COMMIT_MSG"
  git commit -m "$COMMIT_MSG"
fi

echo "🔄 تشغيل sync_repo.sh لمزامنة الريبو..."
./sync_repo.sh

echo "✅ انتهى update_and_sync.sh"
