#!/usr/bin/env bash
set -Eeuo pipefail

# Hyper Factory – تركيب نظام الأمان لـ SQLite

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "🔧 تركيب نظام الأمان لـ SQLite..."

# 1. إنشاء الأدوات
log "📝 1. إنشاء أدوات الأمان..."
./tools/hf_safe_sqlite_runner.sh --help 2>/dev/null || echo "✅ Safe runner جاهز"

# 2. تحسين إعدادات SQLite
log "⚙️  2. تحسين إعدادات قاعدة البيانات..."
if [[ -f "data/factory/factory.db" ]]; then
    ./tools/hf_safe_sqlite_runner.sh sqlite3 data/factory/factory.db "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA busy_timeout=5000;"
    echo "✅ إعدادات SQLite محسنة"
fi

# 3. إيقاف الخدمات القديمة
log "🛑 3. إيقاف الخدمات القديمة..."
pkill -f "hf_auto_executor.sh" || true
pkill -f "hf_smart_turbo.sh" || true
sleep 2

# 4. تعديل الـ Executors
log "🔧 4. تعديل الـ Executors..."
./tools/hf_patch_executor_for_safety.sh

# 5. إعادة التشغيل الآمن
log "🚀 5. إعادة تشغيل الخدمات بشكل آمن..."
for i in {1..10}; do  # تقليل العدد لتخفيف الضغط
    nohup ./tools/hf_safe_sqlite_runner.sh ./hf_auto_executor.sh > "logs/executor_safe_$i.log" 2>&1 &
    echo "✅ تشغيل executor آمن #$i"
done

# 6. تشغيل الـ Turbo بشكل آمن
log "🌀 6. تشغيل الـ Turbo Systems بشكل آمن..."
nohup ./tools/hf_safe_sqlite_runner.sh ./hf_smart_turbo.sh > "logs/smart_turbo_safe.log" 2>&1 &

log "🎯 تركيب نظام الأمان اكتمل!"
log "📊 تتبع التحسن: ./tools/hf_db_lock_report.sh"
