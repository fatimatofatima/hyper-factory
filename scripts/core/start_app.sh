#!/bin/bash
# start_app.sh

set -e

BASE_DIR="$HOME/hyper-factory"
cd "$BASE_DIR"

APP_ID="$1"
if [ -z "$APP_ID" ]; then
    echo "❌ يجب تحديد معرف التطبيق"
    echo "📋 التطبيقات المتاحة:"
    echo "   - backend_coach"
    echo "   - factory_dashboard"
    exit 1
fi

APP_DIR="$BASE_DIR/apps/$APP_ID"

if [ ! -d "$APP_DIR" ]; then
    echo "❌ التطبيق '$APP_ID' غير موجود"
    exit 1
fi

RUN_SCRIPT="$APP_DIR/run.sh"

if [ ! -f "$RUN_SCRIPT" ]; then
    echo "❌ سكريبت التشغيل غير موجود: $RUN_SCRIPT"
    exit 1
fi

if [ ! -x "$RUN_SCRIPT" ]; then
    echo "🔧 جعل سكريبت التشغيل قابل للتنفيذ..."
    chmod +x "$RUN_SCRIPT"
fi

echo "🚀 تشغيل التطبيق: $APP_ID"
echo "📁 المسار: $APP_DIR"

# تشغيل التطبيق في الخلفية
cd "$APP_DIR"
./run.sh > "$BASE_DIR/logs/apps/$APP_ID.log" 2>&1 &

# حفظ PID
echo $! > "$BASE_DIR/logs/apps/$APP_ID.pid"

echo "✅ تم تشغيل التطبيق $APP_ID"
echo "🔍 تتبع السجلات: tail -f $BASE_DIR/logs/apps/$APP_ID.log"
echo "🆔 PID: $(cat $BASE_DIR/logs/apps/$APP_ID.pid)"
