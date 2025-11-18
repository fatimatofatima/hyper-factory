#!/usr/bin/env bash
# sync_repo.sh - مزامنة Hyper Factory مع GitHub بأمان (بدون أسرار)
# الاستخدام:
#   ./sync_repo.sh [--dry-run] [--repo URL] [--branch NAME]
# المتطلبات: git, bash

set -euo pipefail

ROOT="/root/hyper-factory"
DEFAULT_REPO="https://github.com/fatimatofatima/hyper-factory"
REPO_URL="$DEFAULT_REPO"
DRY_RUN=0
BRANCH_OVERRIDE=""

# =============[ تحليل البرامترز ]==============
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO_URL="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --branch)
      BRANCH_OVERRIDE="$2"
      shift 2
      ;;
    *)
      echo "❌ خيار غير معروف: $1"
      echo "   الاستخدام: $0 [--dry-run] [--repo URL] [--branch NAME]"
      exit 1
      ;;
  esac
done

echo "🚀 بدء مزامنة Hyper Factory"
echo "📁 ROOT      : $ROOT"
echo "🌐 REPO      : $REPO_URL"
echo "🌿 BRANCH    : ${BRANCH_OVERRIDE:-'(auto)'}"
echo "🧪 DRY-RUN   : $DRY_RUN"

# =============[ فحص البيئة الأساسية ]==============
if [[ ! -d "$ROOT" ]]; then
  echo "❌ المجلد $ROOT غير موجود"
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "❌ الأمر 'git' غير متوفر على النظام"
  exit 1
fi

cd "$ROOT"

# =============[ .gitignore قوي ]==============
echo "🛡️ ضبط .gitignore..."
cat > .gitignore <<'GIT'
# Python
__pycache__/
*.pyc
*.pyo

# Envs
.env
.env.*
venv/
apps/*/venv/

# Logs & reports
logs/
reports/
audit/
*.log

# Datasets & PDFs (تحفظ محليًا)
ai/pdfs/
ai/datasets/
ai/knowledge/
ai/raw_knowledge/

# Cache & tmp
.tmp/
.cache/
*.swp

# Docker & compose overrides
docker-compose.override.yml

# OS/Editor
.DS_Store
Thumbs.db
.idea/
.vscode/
GIT

# =============[ README.md تلقائي ]==============
echo "📄 توليد README.md..."
cat > README.md <<'MD'
# 🏭 Hyper Factory

منصة تجريبية لبناء "عمال أذكياء" فوق Orchestrator + Memory + Knowledge + Feedback.

## المكونات

- `apps/backend_coach`: خدمة FastAPI على المنفذ 9090.
- `scripts/core`: سكربتات المصنع (ffactory، init، status، start/stop).
- `scripts/ai`: المهارات، العنكبوت، orchestrator الخاص بالـ LLM، القياسات.
- `config/`: ملف `orchestrator.yaml` وباقي ملفات التكوين.
- `logs/` و `reports/`: تبقى محليًا وغير مرفوعة إلى GitHub.

## التشغيل السريع

    ./scripts/core/ffactory.sh init
    ./scripts/core/ffactory.sh start backend_coach
    curl http://localhost:9090/api/health

## الرخصة

هذا مشروع تجريبي/تعليمي.
MD

# =============[ تهيئة/تحديث Git ]==============
echo "🔧 فحص حالة Git في $ROOT..."

INSIDE_GIT=0
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  INSIDE_GIT=1
fi

if [[ $INSIDE_GIT -eq 0 ]]; then
  echo "🆕 لا يوجد مستودع Git، سيتم التهيئة..."
  if [[ $DRY_RUN -eq 0 ]]; then
    git init
    if git remote | grep -q '^origin$' 2>/dev/null; then
      git remote set-url origin "$REPO_URL"
    else
      git remote add origin "$REPO_URL"
    fi
  else
    echo "🧪 [DRY-RUN] git init"
    echo "🧪 [DRY-RUN] git remote add origin $REPO_URL"
  fi
else
  echo "ℹ️ مستودع Git موجود بالفعل."
  if [[ $DRY_RUN -eq 0 ]]; then
    if git remote | grep -q '^origin$' 2>/dev/null; then
      git remote set-url origin "$REPO_URL"
      echo "🔁 تحديث remote origin إلى: $REPO_URL"
    else
      git remote add origin "$REPO_URL"
      echo "🔁 تعيين remote origin إلى: $REPO_URL"
    fi
  else
    echo "🧪 [DRY-RUN] git remote set-url/add origin $REPO_URL"
  fi
fi

# =============[ إضافة الملفات الآمنة فقط ]==============
echo "📦 إضافة الملفات الآمنة إلى Git (SAFE_FILES)..."

SAFE_FILES=(
  "apps/backend_coach/"
  "scripts/"
  "config/"
  ".gitignore"
  "README.md"
)

if [[ $DRY_RUN -eq 0 ]]; then
  for file in "${SAFE_FILES[@]}"; do
    if [[ -e "$file" ]]; then
      git add "$file"
      echo "✅ أضيف: $file"
    else
      echo "⚠️ غير موجود (تجاهل): $file"
    fi
  done
else
  echo "🧪 [DRY-RUN] سيتم إضافة الملفات التالية لو كانت موجودة:"
  printf '    %s\n' "${SAFE_FILES[@]}"
fi

# =============[ Commit التغييرات ]==============
if [[ $DRY_RUN -eq 0 ]]; then
  if git diff --cached --quiet; then
    echo "📝 لا توجد تغييرات جديدة جاهزة للـ commit."
  else
    COMMIT_MSG="Sync: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "📝 إنشاء commit: $COMMIT_MSG"
    git commit -m "$COMMIT_MSG"
  fi
else
  echo "🧪 [DRY-RUN] git commit -m 'Sync: <timestamp>' (في حالة وجود تغييرات)"
fi

# =============[ Push إلى GitHub ]==============
if [[ $DRY_RUN -eq 0 ]]; then
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    # تحديد الفرع المستهدف
    if [[ -n "$BRANCH_OVERRIDE" ]]; then
      TARGET_BRANCH="$BRANCH_OVERRIDE"
    else
      TARGET_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo main)"
    fi

    echo "🔄 محاولة الدفع إلى origin/$TARGET_BRANCH ..."
    if git push -u origin "$TARGET_BRANCH"; then
      echo "🎉 تم دفع التغييرات إلى origin/$TARGET_BRANCH بنجاح!"
    else
      echo "⚠️ فشل الدفع إلى $TARGET_BRANCH، سيتم تجربة master..."
      if git push -u origin master; then
        echo "🎉 تم دفع التغييرات إلى origin/master بنجاح!"
      else
        echo "❌ فشل push إلى كلٍ من $TARGET_BRANCH و master، راجع الرسائل أعلاه."
        exit 1
      fi
    fi
  else
    echo "ℹ️ لا يوجد HEAD (لم يتم إنشاء commit بعد)، لا يوجد ما يُدفع."
  fi
else
  echo "🧪 [DRY-RUN] git push -u origin <branch>"
fi

echo "✅ انتهت المزامنة - الأسرار والبيانات الثقيلة خارج الريبو."
