#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

ROOT_DIR="/root/hyper-factory"
DB="$ROOT_DIR/data/factory/factory.db"
LOG_DIR="$ROOT_DIR/logs"
RUNNER="$ROOT_DIR/tools/hf_safe_sqlite_runner.sh"
EXEC="$ROOT_DIR/hf_auto_executor.sh"
TURBO="$ROOT_DIR/hf_smart_turbo.sh"

log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

cd "$ROOT_DIR"

if [[ ! -f "$DB" ]]; then
  log "❌ قاعدة البيانات غير موجودة: $DB"
  exit 1
fi

if [[ ! -x "$RUNNER" ]] || [[ ! -x "$EXEC" ]] || [[ ! -x "$TURBO" ]]; then
  log "❌ تأكد أن السكربتات التنفيذية RUNNER/EXEC/TURBO موجودة وقابلة للتشغيل."
  exit 1
fi

mkdir -p "$LOG_DIR"

CPU=$(nproc || echo 4)

# يمكن تعديلهم قبل التشغيل عبر متغيرات البيئة
NUM_EXECUTORS=${NUM_EXECUTORS:-$((CPU * 3))}
NUM_TURBO=${NUM_TURBO:-$((CPU / 2))}
if (( NUM_TURBO < 1 )); then NUM_TURBO=1; fi

log "════════ Hyper Factory – Max Knowledge Mode ════════"
log "CPU        : $CPU"
log "EXECUTORS  : $NUM_EXECUTORS (hf_auto_executor)"
log "TURBO NODES: $NUM_TURBO (hf_smart_turbo)"
log "DB         : $DB"

log "1) إيقاف أي عمليات قديمة مرتبطة بالمصنع..."
pkill -f "hf_safe_sqlite_runner.sh" 2>/dev/null || true
pkill -f "hf_auto_executor.sh" 2>/dev/null || true
pkill -f "hf_smart_turbo.sh" 2>/dev/null || true
pkill -f "hf_24_7_autopilot.sh" 2>/dev/null || true
pkill -f "hf_advanced_executor_manager.sh" 2>/dev/null || true

log "2) ضبط إعدادات SQLite لأقصى قدرة (WAL + busy_timeout=5000)..."
"$RUNNER" sqlite3 "$DB" "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA busy_timeout=5000;" \
  >"$LOG_DIR/sqlite_pragma_max_mode.log" 2>&1 || true

log "3) تشغيل أسطول الـ Executors بدون أي sleep في طبقة الإدارة..."
for i in $(seq 1 "$NUM_EXECUTORS"); do
  LOG_FILE="$LOG_DIR/executor_max_${i}.log"
  nohup "$RUNNER" "$EXEC" >"$LOG_FILE" 2>&1 &
  PID=$!
  log "🚀 Executor#$i PID=$PID LOG=$(basename "$LOG_FILE")"
done

log "4) تشغيل عقد Turbo متعددة لرفع تنوع مصادر المعرفة..."
for i in $(seq 1 "$NUM_TURBO"); do
  LOG_FILE="$LOG_DIR/turbo_max_${i}.log"
  nohup "$RUNNER" "$TURBO" >"$LOG_FILE" 2>&1 &
  PID=$!
  log "⚡ Turbo#$i PID=$PID LOG=$(basename "$LOG_FILE")"
done

log "5) ملخص العمليات النشطة:"
ps aux | grep -E "(hf_safe_sqlite_runner|hf_auto_executor|hf_smart_turbo)" | grep -v grep || log "⚠️ لا توجد عمليات نشطة (تحقق من السجلات)."

log "✅ Max Knowledge Mode شغّال. المصنع الآن يعمل بأقصى طاقة ممكنة ضمن حدود SQLite."
