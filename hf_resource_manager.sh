#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "💾 Hyper Factory – Resource Manager"
echo "==================================="

# 1. فحص مساحة القرص
echo "1. 📊 فحص استخدام الموارد..."
DISK_USAGE=$(df /root | awk 'NR==2 {print $5}' | sed 's/%//')
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')

echo "💾 استخدام القرص: $DISK_USAGE%"
echo "🧠 استخدام الذاكرة: $MEMORY_USAGE%"

# 2. ضبط مستوى التشغيل حسب الموارد
if [ "$DISK_USAGE" -gt 85 ] || [ "$MEMORY_USAGE" -gt 80 ]; then
    echo "⚠️ موارد منخفضة - تقليل النشاط"
    # تقليل عدد المهام المتوازية
    sqlite3 "$ROOT/data/factory/factory.db" "
    UPDATE system_settings 
    SET value = 'low', updated_at = CURRENT_TIMESTAMP 
    WHERE key = 'activity_level';"
else
    echo "✅ موارد جيدة - نشاط عادي"
    sqlite3 "$ROOT/data/factory/factory.db" "
    UPDATE system_settings 
    SET value = 'normal', updated_at = CURRENT_TIMESTAMP 
    WHERE key = 'activity_level';"
fi

# 3. تنظيف الملفات المؤقتة
echo "3. 🧹 تنظيف الموارد..."
find "$ROOT/logs" -name "*.log" -mtime +7 -exec gzip {} \;
find "$ROOT/reports" -name "*.txt" -mtime +3 -exec gzip {} \;

echo "✅ Resource Manager اكتمل"
