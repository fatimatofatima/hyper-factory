#!/usr/bin/env bash
set -Eeuo pipefail

echo "🔍 Hyper Factory - Fixed Health Check"
echo "====================================="
echo "⏰ $(date '+%Y-%m-%d %H:%M:%S')"
echo

# فحص العمليات النشطة
echo "📊 1. Active Processes Check..."
ps aux | grep -E "hf_|python.*hyper" | grep -v grep | head -10

# فحص المساحة
echo "💾 2. Disk Space Check..."
df -h / | tail -1

# فحص الذاكرة
echo "🧠 3. Memory Check..."
free -h

# فحص قاعدة البيانات
echo "🗄️  4. Database Check..."
if [[ -f "data/factory/factory.db" ]]; then
    echo "✅ Database exists ($(du -h data/factory/factory.db | cut -f1))"
else
    echo "❌ Database not found"
fi

echo "✅ Fixed health check completed!"
