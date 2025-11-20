#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$ROOT/logs/24_7_autopilot.log"
PID_FILE="$ROOT/logs/24_7_autopilot.pid"

# إنشاء المجلدات اللازمة
mkdir -p "$ROOT/logs"

echo "🚀 Hyper Factory – 24/7 Autopilot" | tee -a "$LOG_FILE"
echo "==================================" | tee -a "$LOG_FILE"
echo "⏰ بدء التشغيل: $(date)" | tee -a "$LOG_FILE"
echo "📁 ROOT: $ROOT" | tee -a "$LOG_FILE"
echo "📄 LOG: $LOG_FILE" | tee -a "$LOG_FILE"
echo "🔒 PID: $$" | tee -a "$LOG_FILE"
echo "$$" > "$PID_FILE"

# دالة لمعالجة الإشارات
cleanup() {
    echo "🛑 استقبال إشارة إيقاف - إنهاء آمن..." | tee -a "$LOG_FILE"
    rm -f "$PID_FILE"
    exit 0
}

trap cleanup SIGTERM SIGINT

# عداد الدورات
CYCLE_COUNT=0
MAX_CYCLES=10080  # أسبوع واحد (دورة كل دقيقة)

while [ $CYCLE_COUNT -lt $MAX_CYCLES ]; do
    CYCLE_COUNT=$((CYCLE_COUNT + 1))
    CYCLE_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "" | tee -a "$LOG_FILE"
    echo "🔄 الدورة $CYCLE_COUNT/$MAX_CYCLES - $CYCLE_TIME" | tee -a "$LOG_FILE"
    echo "==========================================" | tee -a "$LOG_FILE"
    
    # 1. تشغيل المدير اليومي
    echo "📅 تشغيل المدير اليومي..." | tee -a "$LOG_FILE"
    if ! ./hf_factory_manager_daily.sh >> "$LOG_FILE" 2>&1; then
        echo "⚠️ خطأ في المدير اليومي - متابعة..." | tee -a "$LOG_FILE"
    fi
    
    # 2. تشغيل الطيار الآلي
    echo "🤖 تشغيل الطيار الآلي..." | tee -a "$LOG_FILE"
    if ! ./hf_factory_autopilot.sh >> "$LOG_FILE" 2>&1; then
        echo "⚠️ خطأ في الطيار الآلي - متابعة..." | tee -a "$LOG_FILE"
    fi
    
    # 3. تشغيل السمارت رن
    echo "🧠 تشغيل التشغيل الذكي..." | tee -a "$LOG_FILE"
    if ! ./hf_factory_smart_run.sh >> "$LOG_FILE" 2>&1; then
        echo "⚠️ خطأ في التشغيل الذكي - متابعة..." | tee -a "$LOG_FILE"
    fi
    
    # 4. تحديث الأداء
    echo "📈 تحديث أداء العمال..." | tee -a "$LOG_FILE"
    if ! ./hf_auto_performance_updater.sh >> "$LOG_FILE" 2>&1; then
        echo "⚠️ خطأ في تحديث الأداء - متابعة..." | tee -a "$LOG_FILE"
    fi
    
    # 5. فحص الصحة
    echo "🩺 فحص صحة النظام..." | tee -a "$LOG_FILE"
    if ! ./hf_factory_health_check.sh >> "$LOG_FILE" 2>&1; then
        echo "⚠️ خطأ في فحص الصحة - متابعة..." | tee -a "$LOG_FILE"
    fi
    
    # 6. نسخ احتياطي كل 60 دورة (ساعة)
    if [ $((CYCLE_COUNT % 60)) -eq 0 ]; then
        echo "💾 نسخ احتياطي تلقائي..." | tee -a "$LOG_FILE"
        if ! ./hf_backup_snapshot.sh >> "$LOG_FILE" 2>&1; then
            echo "⚠️ خطأ في النسخ الاحتياطي - متابعة..." | tee -a "$LOG_FILE"
        fi
    fi
    
    # 7. مزامنة GitHub كل 120 دورة (ساعتين)
    if [ $((CYCLE_COUNT % 120)) -eq 0 ]; then
        echo "🔄 مزامنة مع GitHub..." | tee -a "$LOG_FILE"
        if ! ./hf_sync_code.sh >> "$LOG_FILE" 2>&1; then
            echo "⚠️ خطأ في المزامنة - متابعة..." | tee -a "$LOG_FILE"
        fi
    fi
    
    # 8. تقرير الحالة كل 10 دورات
    if [ $((CYCLE_COUNT % 10)) -eq 0 ]; then
        echo "📊 تقرير حالة النظام..." | tee -a "$LOG_FILE"
        echo "🕒 وقت التشغيل: $((CYCLE_COUNT)) دورة" | tee -a "$LOG_FILE"
        echo "📈 المهام: $(sqlite3 data/factory/factory.db "SELECT COUNT(*) FROM tasks;")" | tee -a "$LOG_FILE"
        echo "✅ المكتملة: $(sqlite3 data/factory/factory.db "SELECT COUNT(*) FROM tasks WHERE status='done';")" | tee -a "$LOG_FILE"
        echo "⏳ في الطابور: $(sqlite3 data/factory/factory.db "SELECT COUNT(*) FROM tasks WHERE status='queued';")" | tee -a "$LOG_FILE"
    fi
    
    # انتظار 60 ثانية للدورة التالية
    echo "⏳ انتظار 60 ثانية للدورة التالية..." | tee -a "$LOG_FILE"
    sleep 0.1
done

echo "🏁 اكتملت العدد الأقصى للدورات ($MAX_CYCLES) - إعادة التشغيل..." | tee -a "$LOG_FILE"
rm -f "$PID_FILE"

# إعادة التشغيل التلقائي
exec "$0" "$@"
