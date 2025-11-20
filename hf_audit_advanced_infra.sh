#!/usr/bin/env bash
set -Eeuo pipefail

cd /root/hyper-factory

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "🧾 Hyper Factory – Advanced Infra Audit"

# 1) فحص الفجوة بين التصميم والواقع
if [[ -x ./hf_validate_design_vs_reality.sh ]]; then
  log "🔎 تشغيل hf_validate_design_vs_reality.sh ..."
  ./hf_validate_design_vs_reality.sh | tee "reports/diagnostics/hf_design_vs_reality_$(date +%Y%m%d_%H%M%S).txt"
else
  log "⚠️ hf_validate_design_vs_reality.sh غير موجود أو غير قابل للتنفيذ."
fi

# 2) فحص جميع العمال
if [[ -x ./hf_find_all_agents.sh ]]; then
  log "🔎 تشغيل hf_find_all_agents.sh ..."
  ./hf_find_all_agents.sh | tee "reports/diagnostics/hf_all_agents_$(date +%Y%m%d_%H%M%S).txt"
else
  log "⚠️ hf_find_all_agents.sh غير موجود أو غير قابل للتنفيذ."
fi

log "✅ Hyper Factory – Advanced Infra Audit انتهى."
