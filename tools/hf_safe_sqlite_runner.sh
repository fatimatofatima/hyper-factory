#!/usr/bin/env bash
set -Eeuo pipefail

# Hyper Factory – SQLite Safe Runner (Enhanced)
log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2; }
fail() { echo "❌ $*" >&2; exit 1; }

if [ "$#" -lt 1 ]; then
  fail "Usage: $0 <command...>"
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_FILE="$ROOT_DIR/run/sqlite_factory.lock"
MAX_RETRIES=8  # زيادة عدد المحاولات
RETRY_DELAY=1  # بداية من 1 ثانية

mkdir -p "$(dirname "$LOCK_FILE")"

CMD=("$@")

log "🔒 SQLite-safe wrapper starting"
log "COMMAND: ${CMD[*]}"

for ((attempt=1; attempt<=MAX_RETRIES; attempt++)); do
    if (
        flock -x -w 5 200 || exit 1
        log "✅ Lock acquired (attempt $attempt). Executing command..."
        "${CMD[@]}"
        exit $?
    ) 200>"$LOCK_FILE"; then
        log "Command finished successfully"
        exit 0
    else
        if [ $attempt -eq $MAX_RETRIES ]; then
            fail "❌ Failed to acquire lock after $MAX_RETRIES attempts"
        fi
        delay=$((RETRY_DELAY * (2 ** (attempt-1))))
        log "⚠️ Database locked (attempt $attempt), retrying in ${delay}s..."
        sleep $delay
    fi
done
