#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "Hyper Factory – Git Noise Cleaner"
echo "ROOT : $ROOT"
echo

if ! command -v git >/dev/null 2>&1 || [ ! -d ".git" ]; then
  echo "ERROR : هذا المجلد ليس مستودع git أو git غير مثبت."
  exit 1
fi

# تحديد مسار DB المستهدف
DB_PATH_INPUT="${1:-}"
DB_PATH_ENV="${DB_PATH:-}"
DB_TARGET=""

if [ -n "$DB_PATH_INPUT" ]; then
  DB_TARGET="$DB_PATH_INPUT"
elif [ -n "$DB_PATH_ENV" ]; then
  DB_TARGET="$DB_PATH_ENV"
else
  # افتراضي شائع في hyper-factory
  DB_TARGET="data/factory/factory.db"
fi

ensure_gitignore_entry() {
  local pattern="$1"
  if [ ! -f .gitignore ]; then
    touch .gitignore
  fi
  if ! grep -qxF "$pattern" .gitignore 2>/dev/null; then
    echo "$pattern" >> .gitignore
    echo "ADD  .gitignore : $pattern"
  else
    echo "KEEP .gitignore : $pattern (موجود بالفعل)"
  fi
}

echo "1) تحديث .gitignore بالأنماط القياسية (logs, reports, data, *.db, *.sqlite)"
echo "---------------------------------------------------------------------------"
ensure_gitignore_entry "logs/"
ensure_gitignore_entry "reports/"
ensure_gitignore_entry "data/"
ensure_gitignore_entry "*.db"
ensure_gitignore_entry "*.sqlite"
echo

echo "2) إزالة تتبع git عن مجلدات logs/ و reports/ إن كانت متتبَّعة"
echo "-----------------------------------------------------------"
for d in logs reports; do
  if git ls-files --error-unmatch "$d" >/dev/null 2>&1; then
    echo "git rm -r --cached $d"
    git rm -r --cached "$d"
  else
    echo "SKIP : $d غير متتبَّع في git."
  fi
done
echo

echo "3) إزالة ملف قاعدة البيانات من git إن كان متتبَّعًا"
echo "-------------------------------------------------"
if [ -n "$DB_TARGET" ]; then
  if git ls-files --error-unmatch "$DB_TARGET" >/dev/null 2>&1; then
    echo "git rm --cached $DB_TARGET"
    git rm --cached "$DB_TARGET"
  else
    echo "SKIP : $DB_TARGET غير متتبَّع في git (أو غير موجود)."
  fi
else
  echo "INFO : لم يتم تحديد DB_PATH (لا من الباراميتر ولا من البيئة)."
fi
echo

echo "4) حالة git بعد التنظيف (لم يتم عمل commit تلقائيًا)"
echo "----------------------------------------------------"
git status -sb || true

echo
echo "ملاحظة:"
echo "- تم تعديل .gitignore وإزالة تتبع بعض العناصر من index فقط."
echo "- تحتاج لتنفيذ commit يدويًا لتثبيت التغييرات، مثال:"
echo "    git add .gitignore"
echo "    git commit -m 'Clean git noise (logs, reports, DB_PATH)'"
