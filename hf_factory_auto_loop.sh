#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

MAX_CYCLES=${1:-10}  # عدد الدورات (افتراضي 10)
SLEEP_TIME=${2:-30}  # وقت الانتظار بين الدورات (ثواني)

echo "🔄 Hyper Factory – Auto Continuous Loop"
echo "======================================="
echo "⏰ بدء التشغيل: $(date)"
echo "🔁 عدد الدورات: $MAX_CYCLES"
echo "⏱️  وقت الانتظار: $SLEEP_TIME ثانية"
echo ""

for ((cycle=1; cycle<=MAX_CYCLES; cycle++)); do
    echo "🎯 الدورة $cycle من $MAX_CYCLES"
    echo "=========================="
    
    # تشغيل دورة كاملة
    ./hf_full_auto_cycle.sh
    
    # انتظار قبل الدورة التالية
    if [ $cycle -lt $MAX_CYCLES ]; then
        echo "⏳ انتظار $SLEEP_TIME ثانية للدورة التالية..."
        sleep $SLEEP_TIME
        echo ""
    fi
done

echo "✅ اكتملت جميع الدورات في: $(date)"
