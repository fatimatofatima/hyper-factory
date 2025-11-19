#!/usr/bin/env bash
set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

LOG_DIR="$ROOT/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/hf_auto_manager_cycle.log"

ts="$(date -Is)"

log() {
  echo "[$ts] $*" >> "$LOG_FILE"
}

log "=== Hyper Factory Auto Manager Cycle ==="

# 1) فحص الصحة العامة من health_check_report.json
HEALTH_JSON="$ROOT/reports/health_check_report.json"
health_status="unknown"
if [ -f "$HEALTH_JSON" ]; then
  health_status="$(jq -r '.status // "unknown"' "$HEALTH_JSON" 2>/dev/null || echo "unknown")"
else
  log "WARN: health_check_report.json غير موجود – اعتباره unknown"
fi

if [ "$health_status" != "ok" ]; then
  log "SKIP: health_status=$health_status (لن يتم تشغيل الدورة)"
  exit 0
fi

# 2) قراءة ملخص الأداء من summary_basic.json (اختياري)
SUMMARY_JSON="$ROOT/data/report/summary_basic.json"
global_success_rate=""
total_runs=""
if [ -f "$SUMMARY_JSON" ]; then
  global_success_rate="$(jq -r 'try .global_success_rate // empty' "$SUMMARY_JSON" 2>/dev/null || echo "")"
  total_runs="$(jq -r 'try .total_runs // empty' "$SUMMARY_JSON" 2>/dev/null || echo "")"
else
  log "INFO: لا يوجد summary_basic.json بعد – سيتم التشغيل بوضع التعلم المبكر."
fi

# تحويل success_rate إلى قيمة رقمية مع افتراض 1.0 لو غير معروف
if [ -z "$global_success_rate" ] || [ "$global_success_rate" = "null" ]; then
  global_success_rate="1.0"
fi

MIN_SUCCESS_RATE="0.85"

is_success_ok="$(awk -v sr="$global_success_rate" -v min="$MIN_SUCCESS_RATE" 'BEGIN {
  if (sr+0 >= min+0) print "yes"; else print "no";
}')"

# 3) نسبة امتلاء الديسك على /
disk_pct="$(df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')"
MAX_DISK_PCT=90

if [ "$disk_pct" -ge "$MAX_DISK_PCT" ]; then
  log "SKIP: disk usage=${disk_pct}% (>= ${MAX_DISK_PCT}%) – حماية من امتلاء الديسك"
  exit 0
fi

# 4) آخر تقرير Manager (عشان التسجيل فقط)
last_manager_txt="$(ls -1 "$ROOT"/reports/management/*_manager_daily_overview.txt 2>/dev/null | sort | tail -n1 || true)"
manager_age_min="N/A"
if [ -n "$last_manager_txt" ]; then
  now_ts="$(date +%s)"
  mtime_ts="$(stat -c %Y "$last_manager_txt")"
  manager_age_min="$(( (now_ts - mtime_ts) / 60 ))"
fi

log "INFO: health_status=$health_status, success_rate=$global_success_rate, total_runs=${total_runs:-N/A}, disk=${disk_pct}%, manager_age_min=${manager_age_min}"

# 5) قرار التشغيل
if [ "$is_success_ok" != "yes" ]; then
  log "SKIP: global_success_rate=$global_success_rate أقل من الحد الأدنى $MIN_SUCCESS_RATE – يمكن تعديل السياسة لاحقاً."
  exit 0
fi

log "ACTION: تشغيل run_basic_with_memory.sh ثم hf_run_manager_dashboard.sh"

if ./run_basic_with_memory.sh >> "$LOG_FILE" 2>&1; then
  log "OK: run_basic_with_memory.sh انتهى بنجاح."
else
  log "ERROR: فشل run_basic_with_memory.sh – لن يتم إيقاف التايمر لكن تحتاج مراجعة."
  exit 0
fi

if ./hf_run_manager_dashboard.sh >> "$LOG_FILE" 2>&1; then
  log "OK: hf_run_manager_dashboard.sh انتهى بنجاح."
else
  log "ERROR: فشل hf_run_manager_dashboard.sh – راجع اللوج."
fi

log "=== نهاية دورة Hyper Factory Auto Manager ==="
