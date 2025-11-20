#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT/logs/audit"
REPORT_DIR="$ROOT/reports"

mkdir -p "$LOG_DIR" "$REPORT_DIR"

NOW="$(date +%Y-%m-%dT%H:%M:%S)"
LOG_FILE="$LOG_DIR/hf_audit_${NOW//:/-}.log"
REPORT_FILE="$REPORT_DIR/hf_advanced_infra_${NOW//:/-}.txt"

exec > >(tee -a "$LOG_FILE") 2>&1

section() {
  echo
  echo "════════════════════════════════════════════"
  echo "  $1"
  echo "════════════════════════════════════════════"
}

echo "Hyper Factory – Advanced Infra Audit"
echo "Time   : $NOW"
echo "ROOT   : $ROOT"
echo "Report : $REPORT_FILE"
echo

{
  section "1) موارد النظام (df / free)"
  echo "df -h:"
  df -h || true
  echo
  echo "free -h:"
  free -h || true

  section "2) هيكل البيانات (data / logs / reports)"
  for d in "$ROOT/data" "$ROOT/logs" "$ROOT/reports"; do
    if [ -d "$d" ]; then
      echo "DIR OK : $d"
      echo "  المحتوى (أقصى عمق 2):"
      find "$d" -maxdepth 2 -mindepth 1 -printf '    %y %p\n' 2>/dev/null | sort || true
    else
      echo "DIR MISS : $d غير موجود"
    fi
    echo
  done

  section "3) ملفات قواعد البيانات الفعلية داخل المشروع"
  if [ -d "$ROOT" ]; then
    find "$ROOT" \
      -maxdepth 6 \
      -type f \( -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" \) \
      -not -path "*/.git/*" \
      -printf '%s %p\n' 2>/dev/null | sort -n || true
  fi

  section "4) ملاحظة"
  echo "هذا التقرير للقراءة والتحليل فقط؛ لا يقوم بأي تعديل تلقائي."
} | tee "$REPORT_FILE"

echo
echo "Log file    : $LOG_FILE"
echo "Text report : $REPORT_FILE"
echo "Status      : التدقيق المتقدم اكتمل."
