#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="/root/hyper-factory"
cd "$ROOT_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

MODE="${1:-aggressive}"

# ضبط مستويات الطاقة
case "$MODE" in
  conservative)
    EXEC_COUNT=1      # Executor واحد
    TURBO_COUNT=1     # Turbo واحد
    ;;
  balanced)
    EXEC_COUNT=3      # 3 عمال تنفيذ
    TURBO_COUNT=1
    ;;
  aggressive)
    EXEC_COUNT=8      # وضع أقصى طاقة: 8 عمال تنفيذ
    TURBO_COUNT=2     # 2 Turbo
    ;;
  *)
    EXEC_COUNT=4
    TURBO_COUNT=1
    ;;
esac

log "⚙️ Hyper Factory – Max Power Mode ($MODE)"
log "   EXECUTORS = $EXEC_COUNT"
log "   TURBO     = $TURBO_COUNT"

# 1) إيقاف كل العمليات القديمة المرتبطة بالمصنع
log "🛑 إيقاف أي عمليات قديمة (hf_safe_sqlite_runner / hf_auto_executor / hf_smart_turbo / hf_24_7 / manager)..."

pkill -f "hf_safe_sqlite_runner.sh" 2>/dev/null || true
pkill -f "hf_auto_executor.sh"      2>/dev/null || true
pkill -f "hf_smart_turbo.sh"        2>/dev/null || true
pkill -f "hf_24_7_autopilot.sh"     2>/dev/null || true
pkill -f "hf_advanced_executor_manager.sh" 2>/dev/null || true

# 2) التأكد أن لا أحد ماسك قاعدة البيانات
log "🔍 فحص أي عمليات ماسكة factory.db..."
if lsof data/factory/factory.db 2>/dev/null; then
  log "⚠️ لازالت هناك عمليات ماسكة قاعدة البيانات – يفضّل إنهائها يدويًا أولاً."
else
  log "✅ لا توجد عمليات ظاهرة ماسكة factory.db."
fi

# 3) ضبط إعدادات SQLite (بدون نوم – يعتمد على hf_safe_sqlite_runner نفسها)
log "🧩 ضبط إعدادات SQLite (WAL + busy_timeout)..."
./tools/hf_safe_sqlite_runner.sh sqlite3 data/factory/factory.db "
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA busy_timeout=5000;
" || log "⚠️ تحذير: قد يكون حدث lock أثناء ضبط PRAGMA – لكن hf_safe_sqlite_runner يتعامل مع ذلك."

# 4) تشغيل أوتوبايلوت 24/7 (مدير المهام)
log "🚀 تشغيل hf_24_7_autopilot (مدير المصنع 24/7)..."
nohup /bin/bash "$ROOT_DIR/hf_24_7_autopilot.sh" \
  > "$ROOT_DIR/logs/hf_24_7_autopilot_max.log" 2>&1 &

# 5) تشغيل مجموعة executors بأقصى طاقة
log "🚀 تشغيل عمال التنفيذ (hf_auto_executor) بعدد: $EXEC_COUNT ..."
for i in $(seq 1 "$EXEC_COUNT"); do
  nohup "$ROOT_DIR/tools/hf_safe_sqlite_runner.sh" "$ROOT_DIR/hf_auto_executor.sh" \
    > "$ROOT_DIR/logs/executor_hp_$i.log" 2>&1 &
  log "   ✅ executor_hp_$i شغّال"
done

# 6) تشغيل Turbo workers لرفع استهلاك المهام والمعرفة
log "🚀 تشغيل Turbo workers (hf_smart_turbo) بعدد: $TURBO_COUNT ..."
for j in $(seq 1 "$TURBO_COUNT"); do
  nohup "$ROOT_DIR/tools/hf_safe_sqlite_runner.sh" "$ROOT_DIR/hf_smart_turbo.sh" \
    > "$ROOT_DIR/logs/turbo_hp_$j.log" 2>&1 &
  log "   ✅ turbo_hp_$j شغّال"
done

# 7) تقرير سريع عن العمليات النشطة
log "📊 العمليات النشطة المرتبطة بالمصنع الآن:"
ps aux | grep -E "(hf_safe_sqlite_runner|hf_auto_executor|hf_smart_turbo|hf_24_7_autopilot)" | grep -v grep || log "⚠️ لا توجد عمليات – راجع السجلات."

log "✅ تم تفعيل وضع أقصى طاقة – المصنع الآن يجب أن يعمل 24/7 بأقصى ما يسمح به SQLite والنظام."
