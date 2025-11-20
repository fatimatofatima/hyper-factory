#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

# ═════════ Hyper Factory – Advanced Executor Manager ═════════
# هدف السكربت:
# - إدارة عدد executors (hf_auto_executor.sh) ديناميكيًا.
# - تشغيل hf_smart_turbo.sh دائمًا.
# - مراقبة database locks + حمل المعالج.
# - تكبير السعة التشغيلية تدريجيًا بدون خنق SQLite.

ROOT_DIR="${HF_ROOT:-/root/hyper-factory}"
DB_PATH="${HF_DB_PATH:-$ROOT_DIR/data/factory/factory.db}"
LOG_DIR="${HF_LOG_DIR:-$ROOT_DIR/logs}"
RUNNER_SCRIPT="${HF_RUNNER_SCRIPT:-$ROOT_DIR/tools/hf_safe_sqlite_runner.sh}"
EXEC_SCRIPT="${HF_EXEC_SCRIPT:-$ROOT_DIR/hf_auto_executor.sh}"
TURBO_SCRIPT="${HF_TURBO_SCRIPT:-$ROOT_DIR/hf_smart_turbo.sh}"

# إعدادات السعة
MIN_EXECUTORS="${HF_MIN_EXECUTORS:-1}"
MAX_EXECUTORS="${HF_MAX_EXECUTORS:-8}"

# فاصل المراقبة بالثواني
CHECK_INTERVAL="${HF_CHECK_INTERVAL:-30}"

# حدود الحمل
CPU_SOFT_FACTOR="${HF_CPU_SOFT_FACTOR:-1.2}"   # أقل من هذا ⇒ مجال للتوسيع
CPU_HARD_FACTOR="${HF_CPU_HARD_FACTOR:-2.0}"   # أكثر من هذا ⇒ تقليل فوراً

# عدد الدورات الهادئة المطلوبة قبل زيادة السعة
CALM_STEPS="${HF_CALM_STEPS:-3}"

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
info() { log "ℹ️  $*"; }
warn() { log "⚠️  $*"; }
err()  { log "❌ $*" >&2; }

# قراءة load + عدد الأنوية
get_load() { awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0"; }
get_cpus() { nproc 2>/dev/null || echo "1"; }

# عدّ رسائل database is locked في كل اللوجات
get_lock_count() {
  local count
  count=$(grep -c "database is locked" "$LOG_DIR"/*.log 2>/dev/null || true)
  echo "${count:-0}"
}

# تتبع الـ executors الذين أطلقهم هذا السكربت
EXEC_PIDS=()
EXEC_LOGS=()

start_executor() {
  local idx=$(( ${#EXEC_PIDS[@]} + 1 ))
  local log_file="$LOG_DIR/executor_dyn_${idx}.log"

  nohup "$RUNNER_SCRIPT" "$EXEC_SCRIPT" >"$log_file" 2>&1 & local_pid=$!
  EXEC_PIDS+=("$local_pid")
  EXEC_LOGS+=("$log_file")
  info "🚀 تشغيل Executor ديناميكي #$idx (PID=$local_pid, LOG=$(basename "$log_file"))"
}

stop_one_executor() {
  local count=${#EXEC_PIDS[@]}
  if (( count == 0 )); then
    warn "لا يوجد Executors ديناميكيون لإيقافهم."
    return 0
  fi

  local idx=$(( count - 1 ))
  local pid="${EXEC_PIDS[$idx]}"
  local log_file="${EXEC_LOGS[$idx]:-}"

  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    info "🧹 إيقاف Executor ديناميكي (PID=$pid, LOG=$(basename "$log_file"))"
  fi

  unset 'EXEC_PIDS[$idx]'
  unset 'EXEC_LOGS[$idx]'
}

cleanup_dead_executors() {
  local new_pids=()
  local new_logs=()
  for i in "${!EXEC_PIDS[@]}"; do
    local pid="${EXEC_PIDS[$i]}"
    local log_file="${EXEC_LOGS[$i]}"
    if kill -0 "$pid" 2>/dev/null; then
      new_pids+=("$pid")
      new_logs+=("$log_file")
    else
      info "🧽 تنظيف Executor منتهي (PID=$pid, LOG=$(basename "$log_file"))"
    fi
  done
  EXEC_PIDS=("${new_pids[@]}")
  EXEC_LOGS=("${new_logs[@]}")
}

ensure_turbo() {
  if pgrep -f "$TURBO_SCRIPT" >/dev/null 2>&1; then
    return 0
  fi

  local log_file="$LOG_DIR/turbo_dyn.log"
  nohup "$RUNNER_SCRIPT" "$TURBO_SCRIPT" >"$log_file" 2>&1 & local_pid=$!
  info "⚡ تشغيل Turbo ديناميكي (PID=$local_pid, LOG=$(basename "$log_file"))"
}

stop_old_processes() {
  info "إيقاف أي عمليات قديمة مرتبطة بـ hyper-factory (executors / turbo / safe runners)..."

  pkill -f "hf_safe_sqlite_runner.sh $EXEC_SCRIPT" 2>/dev/null || true
  pkill -f "$EXEC_SCRIPT" 2>/dev/null || true
  pkill -f "hf_safe_sqlite_runner.sh $TURBO_SCRIPT" 2>/dev/null || true
  pkill -f "$TURBO_SCRIPT" 2>/dev/null || true

  # اختياري: إيقاف autopilot القديم حتى لا يتعارض مع المدير الجديد
  pkill -f "hf_24_7_autopilot.sh" 2>/dev/null || true

  sleep 2

  info "العمليات المتبقية ذات الصلة (للمراجعة فقط):"
  ps aux | grep -E "(hf_safe_sqlite_runner|hf_auto_executor|hf_smart_turbo|hf_24_7_autopilot)" | grep -v grep || true
}

check_pragmas() {
  info "فحص إعدادات SQLite (PRAGMA)..."
  "$RUNNER_SCRIPT" sqlite3 "$DB_PATH" "
PRAGMA journal_mode;
PRAGMA synchronous;
PRAGMA busy_timeout;
" >/tmp/hf_sqlite_pragmas.$$ 2>&1 || true

  info "مخرجات PRAGMA:"
  sed -n '1,10p' /tmp/hf_sqlite_pragmas.$$ || true
  rm -f /tmp/hf_sqlite_pragmas.$$
}

init_env() {
  info "ROOT_DIR = $ROOT_DIR"
  info "DB_PATH  = $DB_PATH"
  info "LOG_DIR  = $LOG_DIR"

  if [[ ! -f "$DB_PATH" ]]; then
    err "ملف قاعدة البيانات غير موجود: $DB_PATH"
    exit 1
  fi

  mkdir -p "$LOG_DIR"

  if [[ ! -x "$RUNNER_SCRIPT" ]]; then
    err "hf_safe_sqlite_runner.sh غير قابل للتنفيذ: $RUNNER_SCRIPT"
    exit 1
  fi
  if [[ ! -x "$EXEC_SCRIPT" ]]; then
    err "hf_auto_executor.sh غير قابل للتنفيذ: $EXEC_SCRIPT"
    exit 1
  fi
  if [[ ! -x "$TURBO_SCRIPT" ]]; then
    err "hf_smart_turbo.sh غير قابل للتنفيذ: $TURBO_SCRIPT"
    exit 1
  fi
}

main_loop() {
  local cpus load soft_limit hard_limit
  local prev_locks current_locks delta_locks
  local calm_counter=0
  local pressure_counter=0
  local cycle=0

  cpus=$(get_cpus)
  soft_limit=$(python3 - <<PY 2>/dev/null || echo "2.0"
cpus = $cpus
factor = float("$CPU_SOFT_FACTOR")
print(max(1.0, cpus * factor))
PY
)
  hard_limit=$(python3 - <<PY 2>/dev/null || echo "4.0"
cpus = $cpus
factor = float("$CPU_HARD_FACTOR")
print(max(1.0, cpus * factor))
PY
)

  info "عدد الأنوية: $cpus"
  info "حد الحمل الناعم (Soft): $soft_limit"
  info "حد الحمل الصلب  (Hard): $hard_limit"
  info "الحد الأدنى للـ executors: $MIN_EXECUTORS"
  info "الحد الأقصى للـ executors: $MAX_EXECUTORS"

  # تشغيل عدد ابتدائي من الـ executors
  for ((i=0; i<MIN_EXECUTORS; i++)); do
    start_executor
  done
  ensure_turbo

  prev_locks=$(get_lock_count)

  while true; do
    ((cycle++))
    sleep "$CHECK_INTERVAL"

    cleanup_dead_executors
    ensure_turbo

    load=$(get_load)
    current_locks=$(get_lock_count)
    delta_locks=$(( current_locks - prev_locks ))
    (( delta_locks < 0 )) && delta_locks=0
    prev_locks=$current_locks

    local exec_count=${#EXEC_PIDS[@]}

    log "📊 دورة #$cycle | Load=$load | Locks_total=$current_locks | Locks_delta=$delta_locks | Executors=$exec_count"

    local action="none"

    # شرط ضغط: Locks جديدة أو حمل أعلى من Hard
    if (( delta_locks > 0 )); then
      ((pressure_counter++))
      calm_counter=0
      if (( exec_count > MIN_EXECUTORS )); then
        stop_one_executor
        action="scale_down_locks"
      else
        warn "Locks مرتفعة لكن لا يمكن تقليل executors أكثر من الحد الأدنى."
      fi
    elif awk "BEGIN {exit !($load > $hard_limit)}"; then
      ((pressure_counter++))
      calm_counter=0
      if (( exec_count > MIN_EXECUTORS )); then
        stop_one_executor
        action="scale_down_load"
      else
        warn "Load مرتفع لكن لا يمكن تقليل executors أكثر من الحد الأدنى."
      fi
    else
      # لا Locks جديدة والحمل داخل الحدود ⇒ ممكن توسعة تدريجية
      ((calm_counter++))
      pressure_counter=0

      if awk "BEGIN {exit !($load < $soft_limit)}"; then
        # الحمل أقل من Soft limit ⇒ قابل للتوسعة
        if (( calm_counter >= CALM_STEPS && exec_count < MAX_EXECUTORS )); then
          start_executor
          calm_counter=0
          action="scale_up"
        fi
      fi
    fi

    log "🧠 قرار الدورة #$cycle: $action (calm=$calm_counter, pressure=$pressure_counter)"
  done
}

usage() {
  cat <<USAGE
Hyper Factory – Advanced Executor Manager

الاستخدام:
  $(basename "$0")

يقوم السكربت بـ:
  - إيقاف executors/turbo القديمة.
  - فحص إعدادات SQLite.
  - تشغيل MIN_EXECUTORS من hf_auto_executor.sh + Turbo واحد.
  - مراقبة load + database locks.
  - زيادة/تقليل عدد executors ديناميكيًا بين [$MIN_EXECUTORS, $MAX_EXECUTORS].

يمكن ضبط الإعدادات عبر متغيرات البيئة قبل التشغيل:
  HF_ROOT, HF_DB_PATH, HF_LOG_DIR
  HF_MIN_EXECUTORS, HF_MAX_EXECUTORS
  HF_CHECK_INTERVAL, HF_CPU_SOFT_FACTOR, HF_CPU_HARD_FACTOR, HF_CALM_STEPS

USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

log "════════ Hyper Factory – Advanced Executor Manager ════════"

init_env
stop_old_processes
check_pragmas
main_loop
