#!/bin/bash
set -e  # إيقاف عند أول خطأ

echo "🚀 بدء تشغيل Backend Coach API v2.0..."
cd "$(dirname "$0")"

BASE_DIR="/root/hyper-factory"
LOG_FILE="$BASE_DIR/logs/apps/backend_coach.log"

# إنشاء مجلد السجلات إذا لم يكن موجوداً
mkdir -p "$(dirname "$LOG_FILE")"

# التحقق من المتطلبات
if [ ! -d "venv" ]; then
    echo "🐍 إنشاء بيئة افتراضية..."
    python3 -m venv venv
fi

# تفعيل البيئة
source venv/bin/activate

# تثبيت/تحديث المتطلبات
echo "📦 تثبيت المتطلبات..."
pip install --upgrade -r requirements.txt

# التحقق من وجود الملفات الأساسية
if [ ! -f "main.py" ]; then
    echo "❌ خطأ: ملف main.py غير موجود"
    exit 1
fi

# تشغيل التطبيق مع إعادة التحميل التلقائي
echo "🌐 تشغيل الخادم على http://0.0.0.0:9090"
echo "📝 السجلات: $LOG_FILE"
echo "🔄 إعادة التحميل التلقائي مفعل"

exec python3 main.py >> "$LOG_FILE" 2>&1
