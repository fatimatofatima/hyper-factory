#!/usr/bin/env bash
# hf_sync_code.sh
# مزامنة كود Hyper Factory من السيرفر إلى GitHub على فرع master فقط
# - يحافظ على فرع main كما هو (لا يقوم بأي عمليات عليه)
# - يرفع فقط الأكواد والسكربتات، بدون بيانات التشغيل الحساسة قدر الإمكان

set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "============================================"
echo "🔄 Hyper Factory – Code Sync (server → GitHub)"
echo "📁 ROOT : $ROOT"
echo "============================================"

# 1) تأكيد أننا على master وليس main
current_branch="$(git rev-parse --abbrev-ref HEAD || echo 'UNKNOWN')"
echo "📌 Current branch: ${current_branch}"

if [[ "$current_branch" != "master" ]]; then
  echo "❌ المزامنة مسموحة فقط على فرع master لحماية فرع main."
  echo "↪️ نفّذ أولاً: git checkout master"
  exit 1
fi

# 2) معلومات عامة عن الريموت والحالة قبل المزامنة
echo
echo "📌 Git remotes:"
git remote -v || echo "⚠️ لا يمكن قراءة git remote"

echo
echo "📌 git status (قبل المزامنة):"
git status --short || echo "⚠️ لا يمكن قراءة git status"

echo
echo "📦 إضافة الأدلة الآمنة إلى الـ staging..."

SAFE_DIRS=(
  "apps/backend_coach"
  "agents"
  "config"
  "scripts"
  "tools"
)

for d in "${SAFE_DIRS[@]}"; do
  if [[ -d "$d" ]]; then
    echo "  ➕ git add $d/"
    git add "$d"
  fi
done

echo
echo "📦 إضافة الملفات الجذرية الآمنة (سكربتات التشغيل)..."

# نستخدم nullglob لتوسيع النمط hf_*.sh فقط لو فيه ملفات
shopt_orig=$(shopt -p nullglob || true)
shopt -s nullglob

ROOT_FILES=(
  "run_basic_cycle.sh"
  "run_basic_with_report.sh"
  "run_basic_with_memory.sh"
  "setup_processor_basic.sh"
  hf_*.sh
)

TO_ADD=()
for f in "${ROOT_FILES[@]}"; do
  if [[ -e "$f" ]]; then
    TO_ADD+=("$f")
  fi
done

# إعادة nullglob لحالته الأصلية
if [[ -n "$shopt_orig" ]]; then
  eval "$shopt_orig"
else
  shopt -u nullglob || true
fi

if (( ${#TO_ADD[@]} > 0 )); then
  echo "  ➕ git add ${TO_ADD[*]}"
  git add "${TO_ADD[@]}"
else
  echo "  ℹ️ لا توجد سكربتات جذرية مطابقة للأنماط المحددة."
fi

echo
echo "📌 فحص التغييرات المجهزة للـ commit..."
if git diff --cached --quiet; then
  echo "ℹ️ لا توجد تغييرات جديدة للمزامنة (staged diff فارغ)."
  exit 0
fi

echo
echo "📝 إنشاء commit جديد..."
MSG="HF sync (server code baseline): $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
git commit -m "$MSG"

echo
echo "🚀 دفع التغييرات إلى origin/master..."
git push origin master

echo
echo "📌 git status (بعد المزامنة):"
git status --short || true

echo
echo "✅ تمّت مزامنة الكود على فرع master بنجاح."
echo "   - فرع main لم يتم لمسه (يبقى نسخة مرجعية قديمة كما هو)."
echo "============================================"
