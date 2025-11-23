#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/root/hyper-factory"
cd "$BASE_DIR"

LOG_DIR="reports/diagnostics"
mkdir -p "$LOG_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
ADV_LOG="$LOG_DIR/hf_advanced_infra_${TS}.txt"
SUMMARY_LOG="$LOG_DIR/hf_comprehensive_summary_${TS}.txt"

echo "=== Hyper Factory Comprehensive Health Check ==="
echo "الوقت: $(date +'%Y-%m-%d %H:%M:%S')"
echo "المجلد: $BASE_DIR"
echo

{
  echo "===== 1) حالة Git ====="
  git status -sb || echo "⚠️ تعذر قراءة حالة Git"

  echo
  echo "===== 2) فحص البنية الأساسية (hf_check_infra.sh) ====="
  if [[ -x "./hf_check_infra.sh" ]]; then
    ./hf_check_infra.sh || echo "⚠️ hf_check_infra.sh رجع خطأ"
  else
    echo "⚠️ hf_check_infra.sh غير موجود أو غير قابل للتنفيذ"
  fi

  echo
  echo "===== 3) فحص البنية المتقدمة (hf_check_advanced_infra.sh) ====="
  if [[ -x "./hf_check_advanced_infra.sh" ]]; then
    ./hf_check_advanced_infra.sh | sed 's/\x1b\[[0-9;]*m//g' | tee "$ADV_LOG"
    echo "تم حفظ تقرير الفحص المتقدم في: $ADV_LOG"
  else
    echo "⚠️ hf_check_advanced_infra.sh غير موجود أو غير قابل للتنفيذ"
  fi

  echo
  echo "===== 4) تشغيل الداشبورد الشامل إن وجد (hf_master_dashboard.sh) ====="
  if [[ -x "./hf_master_dashboard.sh" ]]; then
    ./hf_master_dashboard.sh || echo "⚠️ hf_master_dashboard.sh رجع خطأ"
  else
    echo "ℹ️ hf_master_dashboard.sh غير موجود – تخطي"
  fi

  echo
  echo "===== 5) تشغيل الداشبورد السريع إن وجد (hf_quick_dashboard.sh) ====="
  if [[ -x "./hf_quick_dashboard.sh" ]]; then
    ./hf_quick_dashboard.sh || echo "⚠️ hf_quick_dashboard.sh رجع خطأ"
  else
    echo "ℹ️ hf_quick_dashboard.sh غير موجود – تخطي"
  fi

} | tee "$SUMMARY_LOG"

echo
echo "ملخص الفحص الشامل محفوظ في: $SUMMARY_LOG"
echo "تقرير البنية المتقدمة (إن وجد) في: $ADV_LOG"
echo "انتهى الفحص الشامل."
