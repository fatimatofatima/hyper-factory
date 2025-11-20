#!/usr/bin/env bash
set -Eeuo pipefail

# Hyper Factory – SQLite Safe Runner
# يحل مشكلة database locked باستخدام flock + retry

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
fail() { echo "❌ $*"; exit 1; }

if [ "$#" -lt 1 ]; then
  fail "Usage: $0 <command...>"
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_FILE="$ROOT_DIR/run/sqlite_factory.lock"
MAX_RETRIES=5
RETRY_DELAY=1

mkdir -p "$(dirname "$LOCK_FILE")"

CMD=("$@")

log "🔒 SQLite-safe wrapper starting"
log "ROOT_DIR   = $ROOT_DIR" 
log "LOCK_FILE  = $LOCK_FILE"
log "COMMAND    = ${CMD[*]}"
log "MAX_RETRIES= $MAX_RETRIES"

# تنفيذ مع قفل و retry
for attempt in $(seq 1 $MAX_RETRIES); do
    if flock -n 200; then
        log "✅ Lock acquired (attempt $attempt). Executing command..."
        "${CMD[@]}"
        EXIT_CODE=$?
        log "Command finished with exit code $EXIT_CODE"
        exit $EXIT_CODE
    else
        if [ $attempt -eq $MAX_RETRIES ]; then
            fail "❌ Failed to acquire lock after $MAX_RETRIES attempts"
        fi
        log "⚠️  Database locked (attempt $attempt), retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
        RETRY_DELAY=$((RETRY_DELAY * 2)) # Exponential backoff
    fi
done 200>"$LOCK_FILE"
