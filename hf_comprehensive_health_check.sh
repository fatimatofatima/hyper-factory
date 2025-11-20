#!/usr/bin/env bash
set -Eeuo pipefail

cd /root/hyper-factory

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "🏥 Hyper Factory – Comprehensive Health Check"

# 1) فحص البنية الأساسية
if [[ -x ./hf_check_infra.sh ]]; then
  log "🔎 تشغيل hf_check_infra.sh ..."
  ./hf_check_infra.sh
else
  log "⚠️ hf_check_infra.sh غير موجود أو غير قابل للتنفيذ."
fi

# 2) فحص البنية المتقدمة
if [[ -x ./hf_check_advanced_infra.sh ]]; then
  log "🔎 تشغيل hf_check_advanced_infra.sh ..."
  ./hf_check_advanced_infra.sh | sed 's/\x1b\[[0-9;]*m//g' | tee reports/diagnostics/hf_advanced_infra_check.txt
else
  log "⚠️ hf_check_advanced_infra.sh غير موجود أو غير قابل للتنفيذ."
fi

# 3) تقرير أقفال SQLite
if [[ -x ./tools/hf_db_lock_report.sh ]]; then
  log "🔎 تشغيل tools/hf_db_lock_report.sh ..."
  ./tools/hf_db_lock_report.sh | tee "reports/diagnostics/hf_db_lock_report_$(date +%Y%m%d_%H%M%S).txt"
else
  log "⚠️ tools/hf_db_lock_report.sh غير موجود أو غير قابل للتنفيذ."
fi

log "✅ Hyper Factory – Comprehensive Health Check انتهى."
