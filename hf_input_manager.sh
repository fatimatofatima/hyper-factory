#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "📥 Hyper Factory – Input Manager"
echo "================================"

# 1. فحص رسائل المستخدم
echo "1. 🔍 فحص مدخلات المستخدم..."
if [ -d "$ROOT/data/inbox" ]; then
    find "$ROOT/data/inbox" -type f -name "*.txt" -mmin -5 | while read file; do
        DESC=$(head -n 1 "$file")
        echo "📩 معالجة ملف: $file"
        ./hf_factory_cli.sh new "$DESC" "normal"
        mv "$file" "$ROOT/data/inbox/processed/"
    done
fi

# 2. فحص لوجات الأنظمة
echo "2. 📊 فحص لوجات الأنظمة..."
if [ -f "$ROOT/logs/system_errors.log" ]; then
    ERROR_COUNT=$(grep -c "ERROR" "$ROOT/logs/system_errors.log" 2>/dev/null || echo "0")
    if [ "$ERROR_COUNT" -gt 5 ]; then
        echo "🚨 اكتشاف أخطاء نظام: $ERROR_COUNT خطأ"
        ./hf_factory_cli.sh new "معالجة أخطاء النظام الحرجة - تم اكتشاف $ERROR_COUNT خطأ" "high"
    fi
fi

# 3. فحص مساحة السيرفر
echo "3. 💾 فحص موارد السيرفر..."
DISK_USAGE=$(df /root | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "⚠️ مساحة القرص منخفضة: $DISK_USAGE%"
    ./hf_factory_cli.sh new "تنظيف مساحة القرص - الاستخدام $DISK_USAGE%" "high"
fi

echo "✅ Input Manager اكتمل"
