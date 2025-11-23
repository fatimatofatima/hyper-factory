#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/root/hyper-factory"
cd "$BASE_DIR"

LOG_DIR="reports/diagnostics"
mkdir -p "$LOG_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$LOG_DIR/hf_advanced_infra_audit_${TS}.txt"

echo "=== Hyper Factory Advanced Infra Audit ==="
echo "الوقت: $(date +'%Y-%m-%d %H:%M:%S')"
echo "المجلد: $BASE_DIR"
echo

if [[ ! -x "./hf_check_advanced_infra.sh" ]]; then
  echo "❌ السكربت hf_check_advanced_infra.sh غير موجود أو غير قابل للتنفيذ."
  echo "↪ تأكد من وجوده ثم أعد التشغيل."
  exit 1
fi

./hf_check_advanced_infra.sh | sed 's/\x1b\[[0-9;]*m//g' | tee "$OUT_FILE"

echo
echo "✅ تم حفظ تقرير فحص البنية المتقدمة في:"
echo "   $OUT_FILE"
