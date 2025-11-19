#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-/root/hyper-factory}"

cd "$ROOT" 2>/dev/null || { echo "❌ ROOT غير موجود: $ROOT"; exit 1; }

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ هذا المجلد ليس git repo."
  exit 1
fi

echo "📊 Hyper Factory – Git Advanced Status"
echo "======================================"
echo "ROOT: $ROOT"
echo

untracked=$(git status --porcelain | awk '$1=="??"{print $2}')

if [ -z "$untracked" ]; then
  echo "✅ لا توجد ملفات غير متتبعة."
  exit 0
fi

echo "📁 الملفات غير المتتبعة (raw):"
echo "------------------------------"
printf '%s\n' $untracked
echo

code_candidates=()
data_candidates=()

for p in $untracked; do
  case "$p" in
    ai/memory/*|data/*|config_changes/*|reports/*)
      data_candidates+=("$p")
      ;;
    *.sh|*.py|design/*|tools/*)
      code_candidates+=("$p")
      ;;
    *)
      data_candidates+=("$p")
      ;;
  esac
done

echo "💻 مرشحّة كـ CODE (ينصح بمراجعتها ثم إضافتها للـ repo):"
echo "----------------------------------------------------"
if [ ${#code_candidates[@]} -eq 0 ]; then
  echo "  (لا شيء)"
else
  for p in "${code_candidates[@]}"; do
    echo "  - $p"
  done
fi

echo
echo "💾 مرشحّة كـ DATA / Runtime (ينصح إما بإبقائها خارج git أو إضافتها لـ .gitignore):"
echo "-------------------------------------------------------------------------------"
if [ ${#data_candidates[@]} -eq 0 ]; then
  echo "  (لا شيء)"
else
  for p in "${data_candidates[@]}"; do
    echo "  - $p"
  done
fi

echo
echo "🔎 أوامر مقترحة (لا تنفَّذ تلقائيًا):"
echo "-------------------------------------"
if [ ${#code_candidates[@]} -gt 0 ]; then
  echo "# لإضافة سكربتات/كود فقط:"
  echo "git add ${code_candidates[*]}"
  echo "git commit -m \"HF: track advanced scripts\""
fi

echo
echo "# لإنشاء .gitignore متقدم (يدويًا عند الحاجة):"
echo "cat >> .gitignore <<'EOF_GITIGNORE'"
echo "ai/memory/"
echo "data/"
echo "config_changes/"
echo "reports/"
echo "EOF_GITIGNORE"
