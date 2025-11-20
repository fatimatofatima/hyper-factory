#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$ROOT/logs"
RUN_DIR="$ROOT/run"
mkdir -p "$LOG_DIR" "$RUN_DIR"

PID_FILE="$RUN_DIR/hf_24_7.pid"
LOG_FILE="$LOG_DIR/hf_24_7.log"

usage() {
  echo "Usage: $0 {start|stop|status|logs|monitor|restart}"
  exit 1
}

case "${1:-}" in
  start)
    if [ -f "$PID_FILE" ]; then
      PID=$(cat "$PID_FILE")
      if ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ خدمة HF 24/7 تعمل بالفعل (PID=$PID)"
        exit 0
      fi
    fi

    echo "🚀 بدء خدمة HF 24/7..."
    nohup bash -c '
ROOT="'"$ROOT"'"
while true; do
  echo "===== HF 24/7 TICK $(date) ====="
  for script in \
    hf_task_manager.sh \
    hf_auto_researcher.sh \
    hf_self_evaluation_system.sh \
    hf_self_training_system.sh \
    hf_db_architect_brain.sh \
    hf_kpi_snapshot.sh \
    hf_hyper_brain.sh
  do
    if [ -x "$ROOT/$script" ]; then
      echo "[RUN] $script"
      "$ROOT/$script"
    else
      echo "[SKIP] $script (missing or not executable)"
    fi
  done
  echo "===== SLEEP 300s ====="
  sleep 0.1
done
' >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo "✅ تم تشغيل خدمة HF 24/7 (PID=$(cat "$PID_FILE"))"
    ;;

  stop)
    if [ ! -f "$PID_FILE" ]; then
      echo "ℹ️ لا يوجد PID مسجل، الخدمة على الأغلب متوقفة."
      exit 0
    fi
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
      echo "⏹ إيقاف خدمة HF 24/7 (PID=$PID)..."
      kill "$PID" || true
    else
      echo "ℹ️ العملية غير موجودة، سيتم حذف ملف PID."
    fi
    rm -f "$PID_FILE"
    echo "✅ تم إيقاف الخدمة."
    ;;

  status)
    if [ -f "$PID_FILE" ]; then
      PID=$(cat "$PID_FILE")
      if ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ HF 24/7: RUNNING (PID=$PID)"
        exit 0
      else
        echo "⚠️ HF 24/7: PID موجود لكن العملية غير فعّالة."
        exit 1
      fi
    else
      echo "ℹ️ HF 24/7: متوقفة (no PID)."
      exit 3
    fi
    ;;

  logs)
    if [ -f "$LOG_FILE" ]; then
      tail -n 50 "$LOG_FILE"
    else
      echo "ℹ️ لا يوجد لوج بعد: $LOG_FILE"
    fi
    ;;

  monitor)
    if [ ! -f "$LOG_FILE" ]; then
      echo "ℹ️ لا يوجد لوج بعد: $LOG_FILE"
      exit 0
    fi
    tail -f "$LOG_FILE"
    ;;

  restart)
    "$0" stop || true
    "$0" start
    ;;

  *)
    usage
    ;;
esac
