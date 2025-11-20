#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="/root/hyper-factory"
cd "$ROOT_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "════════ Hyper Factory – Full Power Knowledge Mode ════════"

# 1) إيقاف أي عمليات قديمة مرتبطة بالمصنع
log "ℹ️  إيقاف العمليات القديمة (safe runner / executors / turbo / autopilot)..."

pkill -f "hf_safe_sqlite_runner.sh" >/dev/null 2>&1 || true
pkill -f "hf_auto_executor.sh"       >/dev/null 2>&1 || true
pkill -f "hf_smart_turbo.sh"         >/dev/null 2>&1 || true
pkill -f "hf_24_7_autopilot.sh"      >/dev/null 2>&1 || true
pkill -f "hf_24_7_autopilot.sh"      >/dev/null 2>&1 || true

# 2) إصلاح/تهيئة SQLite لو سكربت الإصلاح موجود
if [[ -x "./hf_sqlite_smart_fix.sh" ]]; then
  log "ℹ️  تشغيل hf_sqlite_smart_fix لضبط WAL / busy_timeout قبل وضع أقصى طاقة..."
  ./hf_sqlite_smart_fix.sh || log "⚠️  hf_sqlite_smart_fix رجع بخطأ – نكمل رغم ذلك."
else
  log "ℹ️  لم يتم العثور على hf_sqlite_smart_fix.sh – تخطي خطوة الإصلاح."
fi

# 3) إعداد وضع أقصى طاقة
EXECUTORS=6       # عدد العمال الرئيسيين
TURBO_WORKERS=2   # عدد عمال smart_turbo

log "ℹ️  تشغيل $EXECUTORS executor (hf_auto_executor عبر hf_safe_sqlite_runner)..."

for i in $(seq 1 "$EXECUTORS"); do
  nohup ./tools/hf_safe_sqlite_runner.sh ./hf_auto_executor.sh \
    > "logs/executor_hp_${i}.log" 2>&1 &
  log "🚀 تشغيل executor عالي الطاقة #$i (PID=$!)"
done

log "ℹ️  تشغيل $TURBO_WORKERS smart_turbo (hf_smart_turbo عبر hf_safe_sqlite_runner)..."

for i in $(seq 1 "$TURBO_WORKERS"); do
  nohup ./tools/hf_safe_sqlite_runner.sh ./hf_smart_turbo.sh \
    > "logs/turbo_hp_${i}.log" 2>&1 &
  log "🚀 تشغيل smart_turbo #$i (PID=$!)"
done

# 4) التأكد من تشغيل autopilot 24/7
if pgrep -f "hf_24_7_autopilot.sh" >/dev/null 2>&1; then
  log "ℹ️  hf_24_7_autopilot يعمل بالفعل."
else
  log "ℹ️  تشغيل hf_24_7_autopilot في وضع 24/7..."
  nohup ./hf_24_7_autopilot.sh > "logs/hf_24_7_hp.log" 2>&1 &
  log "🚀 تشغيل hf_24_7_autopilot (PID=$!)"
fi

# 5) ملخص سريع للحالة
log "ℹ️  العمليات النشطة الآن (hf_safe_sqlite_runner / hf_auto_executor / hf_smart_turbo / hf_24_7_autopilot):"
ps aux | grep -E "(hf_safe_sqlite_runner|hf_auto_executor|hf_smart_turbo|hf_24_7_autopilot)" | grep -v grep || true

log "✅ وضع Hyper Factory – Full Power Knowledge Mode مفعّل."
log "ℹ️  للمراقبة، يمكنك تشغيل: ./tools/hf_db_lock_report.sh"
