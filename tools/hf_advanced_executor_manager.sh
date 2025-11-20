#!/usr/bin/env bash
set -Eeuo pipefail

# Hyper Factory – Advanced Executor Manager
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

manage_executors() {
    local max_concurrent=$1
    local instance_id=$2
    
    log "🔄 Starting executor manager (Instance: $instance_id, Max: $max_concurrent)"
    
    while true; do
        # عد العمليات النشطة
        local active_count=$(ps aux | grep "hf_safe_sqlite_runner.sh" | grep -v grep | wc -l)
        
        if [ $active_count -lt $max_concurrent ]; then
            local needed=$((max_concurrent - active_count))
            log "⚡ Starting $needed new executors..."
            
            for ((i=1; i<=needed; i++)); do
                nohup ./tools/hf_safe_sqlite_runner.sh ./hf_auto_executor.sh > \
                    "$LOG_DIR/executor_managed_${instance_id}_$(date +%s)_$i.log" 2>&1 &
            done
        fi
        
        sleep 10
    done
}

# الإعدادات
case "${1:-}" in
    "turbo")
        manage_executors 5 "turbo"  # وضع Turbo - 5 عمليات متزامنة
        ;;
    "balanced")
        manage_executors 8 "balanced"  # وضع متوازن
        ;;
    "conservative")
        manage_executors 3 "conservative"  # وضع محافظ
        ;;
    *)
        echo "Usage: $0 {turbo|balanced|conservative}"
        exit 1
        ;;
esac
