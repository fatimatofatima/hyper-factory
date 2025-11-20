#!/usr/bin/env bash
set -Eeuo pipefail

# Hyper Factory – Comprehensive Health Check
# هدفه: فحص سريع لصحة البنية (مجلدات، قواعد بيانات، بيئة تنفيذ)

log()      { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
ok()       { echo "✅ $*"; }
warn()     { echo "⚠️  $*"; }
fail()     { echo "❌ $*"; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

log "Hyper Factory – Comprehensive Health Check"
log "ROOT_DIR = $ROOT_DIR"
echo

# 1) التحقق من أننا داخل مستودع git
if [ -d ".git" ]; then
  ok "Git repo detected"
else
  warn "Not a git repository (.git missing)"
fi

# 2) فحص المجلدات الأساسية
REQUIRED_DIRS=(
  "data"
  "data/factory"
  "data/knowledge"
  "data/inbox"
  "data/processed"
  "data/semantic"
  "data/serving"
  "reports"
)

log "Checking core directories..."
for d in "${REQUIRED_DIRS[@]}"; do
  if [ -d "$d" ]; then
    ok "DIR exists: $d"
  else
    warn "DIR missing: $d"
  fi
done
echo

# 3) فحص قواعد البيانات الأساسية
DBS=(
  "data/factory/factory.db"
  "data/knowledge/knowledge.db"
)

log "Checking main SQLite databases..."
for db in "${DBS[@]}"; do
  if [ -f "$db" ]; then
    size=$(du -h "$db" | awk '{print $1}')
    ok "DB exists: $db (size: $size)"
    if command -v sqlite3 >/dev/null 2>&1; then
      tables=$(sqlite3 "$db" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>/dev/null || echo "N/A")
      echo "   → tables count: $tables"
    else
      warn "sqlite3 not installed; skipping schema check for $db"
    fi
  else
    warn "DB missing: $db"
  fi
done
echo

# 4) فحص وجود venv أو بيئة Python
log "Checking Python/venv..."
if [ -d "venv" ]; then
  ok "venv directory found (./venv)"
elif [ -d ".venv" ]; then
  ok ".venv directory found (./.venv)"
else
  warn "No virtualenv directory detected (venv or .venv)"
fi

if command -v python3 >/dev/null 2>&1; then
  pyver=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
  ok "python3 found (version: $pyver)"
else
  fail "python3 not found in PATH"
fi
echo

# 5) فحص آخر حالة git مختصرة
if [ -d ".git" ]; then
  log "Git status (short):"
  git status --short || warn "git status failed"
  echo
fi

# 6) ملخص نهائي
log "Health check completed."
