#!/usr/bin/env bash
# Hyper Factory – Continuous Rapid Learning + Unified Control (NO SLEEP)
set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT" || exit 1

echo "♾️ Hyper Factory – Rapid Learning + Control Loop (NO SLEEP – MAX POWER)"

while true; do
    echo "=================================================="
    echo "⏰ دورة جديدة: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo "=================================================="

    ./hf_rapid_learning.sh          || echo "⚠️ rapid_learning فشل في هذه الدورة"
    ./hf_unified_control_system.sh  || echo "⚠️ unified_control فشل في هذه الدورة"
done
