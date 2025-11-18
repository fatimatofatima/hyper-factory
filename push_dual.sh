#!/usr/bin/env bash
# push_dual.sh - إنشاء ودفع الفرعين main و master معًا

set -euo pipefail
ROOT="/root/hyper-factory"
REPO_URL="https://github.com/fatimatofatima/hyper-factory"

cd "$ROOT"

echo "🚀 مزامنة الفرعين main و master إلى $REPO_URL"

# تأكد من وجود remote
if ! git remote | grep -q origin; then
  git remote add origin "$REPO_URL"
fi

# تأكد من وجود commit
git add . || true
git commit -m "Sync before dual push" || true

# دفع master
echo "⬆️ دفع الفرع master..."
git checkout master || git checkout -b master
git push -u origin master

# دفع main
echo "⬆️ دفع الفرع main..."
git checkout -b main || git checkout main
git push -u origin main

echo "✅ تم دفع الفرعين main و master بنجاح!"
