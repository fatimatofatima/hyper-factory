#!/usr/bin/env bash
set -Eeuo pipefail

# Hyper Factory – Git Noise Cleaner
# - إزالة تتبع ملفات البيانات (db + مخرجات) من git مع إبقائها على القرص.
# - تحديث .gitignore بأنماط واضحة.
# - لا يقوم بعمل commit؛ فقط يجهّز الحالة.

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
ok()   { echo "✅ $*"; }
warn() { echo "⚠️  $*"; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -d ".git" ]; then
  echo "❌ This directory is not a git repository (.git missing)"
  exit 1
fi

log "Hyper Factory – Git Noise Cleaner"
log "ROOT_DIR = $ROOT_DIR"
echo

# 1) تعريف المسارات المزعجة (يمكن تعديلها حسب الحاجة)
NOISE_FILES=(
  "data/factory/factory.db"
  "data/knowledge/knowledge.db"
)

NOISE_DIR_PATTERNS=(
  "data/inbox/"
  "data/raw/"
  "data/processed/"
  "data/semantic/"
  "data/serving/"
  "reports/"
)

# 2) تحديث .gitignore
GITIGNORE_FILE=".gitignore"
log "Updating .gitignore ..."

if [ ! -f "$GITIGNORE_FILE" ]; then
  touch "$GITIGNORE_FILE"
fi

{
  echo ""
  echo "# Hyper Factory – data & artefacts (auto-added)"
  for f in "${NOISE_FILES[@]}"; do
    echo "$f"
  done
  for p in "${NOISE_DIR_PATTERNS[@]}"; do
    echo "$p"
  done
} >> "$GITIGNORE_FILE"

ok ".gitignore updated."

# 3) إزالة تتبع ملفات البيانات من git فقط (مع الاحتفاظ بالملف فعليًا)
log "Removing data files from git index (keeping them on disk)..."
for f in "${NOISE_FILES[@]}"; do
  if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
    ok "git rm --cached $f"
    git rm --cached "$f"
  else
    warn "Not tracked (or missing): $f"
  fi
done

# 4) تلخيص الحالة
echo
log "Current git status (short):"
git status --short || warn "git status failed"

echo
ok "Git noise clean-up prepared."
echo "➡️ راجع التغييرات ثم نفّذ commit يدويًا، مثال:"
echo "   git add .gitignore"
echo "   git commit -m 'Clean data artefacts from repo and update .gitignore'"
