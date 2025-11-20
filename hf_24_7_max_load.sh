#!/usr/bin/env bash
set -Eeuo pipefail

cd /root/hyper-factory

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# تحميل بروفايل السعة القصوى
if [[ -f ./tools/hf_capacity_profile_max.sh ]]; then
  # shellcheck disable=SC1091
  source ./tools/hf_capacity_profile_max.sh
else
  log "⚠️ لا يوجد tools/hf_capacity_profile_max.sh – سيتم استخدام قيم افتراضية."
fi

EXECUTORS="${HF_EXECUTORS:-12}"
TURBO="${HF_TURBO_WORKERS:-4}"

log "🚀 تشغيل Hyper Factory بأقصى طاقة: EXECUTORS=${EXECUTORS}, TURBO=${TURBO}"

log "⏹ إيقاف أي safe runners / executors / smart_turbo قديمة..."
pkill -f "hf_safe_sqlite_runner.sh"  >/dev/null 2>&1 || true
pkill -f "hf_auto_executor.sh"       >/dev/null 2>&1 || true
pkill -f "hf_smart_turbo.sh"         >/dev/null 2>&1 || true

sleep 2

log "🧽 تشغيل إصلاح SQLite الذكي قبل البدء..."
if [[ -x ./tools/hf_sqlite_smart_fix.sh ]]; then
  ./tools/hf_sqlite_smart_fix.sh || log "⚠️ hf_sqlite_smart_fix.sh فشل أو أعاد خطأ."
else
  log "⚠️ ./tools/hf_sqlite_smart_fix.sh غير موجود أو غير قابل للتنفيذ."
fi

log "🚀 تشغيل ${EXECUTORS} executor عبر hf_safe_sqlite_runner.sh ..."
for i in $(seq 1 "${EXECUTORS}"); do
  ./tools/hf_safe_sqlite_runner.sh ./hf_auto_executor.sh >>"logs/executor_max_${i}.log" 2>&1 &
done

log "🚀 تشغيل ${TURBO} smart_turbo عبر hf_safe_sqlite_runner.sh ..."
for i in $(seq 1 "${TURBO}"); do
  ./tools/hf_safe_sqlite_runner.sh ./hf_smart_turbo.sh >>"logs/turbo_max_${i}.log" 2>&1 &
done

sleep 2

log "ℹ️ العمليات النشطة الآن (executors / smart_turbo):"
ps aux | grep -E "hf_safe_sqlite_runner.sh|hf_auto_executor.sh|hf_smart_turbo.sh" | grep -v grep || true

log "ℹ️ راقب الأقفال عبر: ./tools/hf_db_lock_report.sh"
