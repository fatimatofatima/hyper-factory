#!/usr/bin/env bash
# run_basic_cycle.sh
# تشغيل دورة كاملة:
# - ingestor_basic (data/inbox -> data/processed)
# - processor_basic (data/processed -> data/semantic)
# - تسجيل نتيجة الدورة في reports/basic_runs.log

set -euo pipefail

ROOT="/root/hyper-factory"

echo "================= 🏭 Hyper Factory Basic Cycle ================="
echo "📁 ROOT : $ROOT"
echo "⏱  TIME : $(date '+%Y-%m-%d %H:%M:%S')"
echo "----------------------------------------------------------------"

cd "$ROOT"

AGENT_ORCH="$ROOT/agents/orchestrator_basic.sh"

if [[ ! -x "$AGENT_ORCH" ]]; then
  echo "❌ orchestrator_basic.sh غير موجود أو غير قابل للتنفيذ: $AGENT_ORCH"
  exit 1
fi

"$AGENT_ORCH"
