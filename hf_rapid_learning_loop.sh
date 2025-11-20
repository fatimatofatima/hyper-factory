#!/usr/bin/env bash
# Hyper Factory – Continuous Rapid Learning + Control Loop
set -euo pipefail

ROOT="/root/hyper-factory"
INTERVAL=60   # غيّرها إلى 30 أو 15 لو عايز أقصى سرعة

cd "$ROOT" || exit 1

echo "♾️ Hyper Factory – Rapid Learning + Control Loop (every ${INTERVAL}s)"

while true; do
    echo "=================================================="
    echo "⏰ دورة جديدة: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo "=================================================="

    # 1) دورة تعلم سريعة
    ./hf_rapid_learning.sh || echo "⚠️ rapid_learning فشل في هذه الدورة"

    # 2) تحديث القياسات ولوحة التحكم
    ./hf_unified_control_system.sh || echo "⚠️ unified_control فشل في هذه الدورة"

    echo "⏳ انتظار ${INTERVAL} ثانية قبل الدورة التالية..."
    sleep "$INTERVAL"
done
