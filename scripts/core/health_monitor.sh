#!/bin/bash
# مراقب صحة المصنع التلقائي

BASE_DIR="/root/hyper-factory"
LOG_FILE="$BASE_DIR/logs/health_monitor.log"

check_service() {
    local service=$1
    local port=$2
    
    if curl -s http://localhost:$port/api/health > /dev/null; then
        echo "✅ $service (port $port) - HEALTHY"
        return 0
    else
        echo "❌ $service (port $port) - DOWN" 
        return 1
    fi
}

log() {
    echo "[$(date)] $1" >> "$LOG_FILE"
}

echo "🏥 فحص صحة المصنع..."
check_service "backend_coach" 9090

# يمكن إضافة المزيد من الخدمات هنا
