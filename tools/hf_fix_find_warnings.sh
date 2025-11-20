#!/usr/bin/env bash
set -Eeuo pipefail

# Hyper Factory – find() Warnings Cleaner
# - الوضع الافتراضي: تقرير فقط (report-only)
# - عند استخدام --apply: محاولة إصلاح نمط شائع في ملفات .sh

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
info() { echo "ℹ️  $*"; }
ok()   { echo "✅ $*"; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE="report"
if [ "${1-}" = "--apply" ]; then
  MODE="apply"
fi

log "Hyper Factory – find() warnings helper (mode: $MODE)"
echo

# 1) البحث عن أوامر find المحتملة فيها مشاكل ترتيب
log "Scanning for suspicious find usage (maxdepth/type order)..."
grep -RIn --exclude-dir='.git' --include='*.sh' 'find ' . 2>/dev/null | \
  grep -E 'maxdepth|mindepth' || {
    info "No suspicious find patterns detected (or none matched the heuristic)."
  }

echo

if [ "$MODE" = "report" ]; then
  info "Report-only mode finished. Use:"
  info "  ./tools/hf_fix_find_warnings.sh --apply"
  info "لتطبيق إصلاح نمطي بسيط على ملفات .sh (مع مراجعة git diff بعده)."
  exit 0
fi

# 2) وضع التطبيق – إصلاح نمط محدد فقط:
#   find . -type f -maxdepth N
#   → find . -maxdepth N -type f
log "Applying simple in-place fix for some find patterns in *.sh ..."

shopt -s nullglob
for f in $(git ls-files '*.sh' 2>/dev/null || echo); do
  perl -pi -e 's/find(\s+\S+)\s+-type\s+([a-zA-Z]+)\s+-maxdepth\s+([0-9]+)/find$1 -maxdepth $3 -type $2/g' "$f"
done
shopt -u nullglob

ok "Pattern-based fix applied. Please review changes with: git diff"
