#!/usr/bin/env bash
# Hyper Factory – Manager Engine Runner (execute manager plan)
set -euo pipefail

ROOT="/root/hyper-factory"
PLAN="$ROOT/run/manager_execution_plan.txt"

cd "$ROOT" || exit 1

echo "🧩 Hyper Factory – Manager Engine (execute plan)"

# توليد الخطة
python3 "$ROOT/tools/hf_manager_brain.py"

if [ ! -f "$PLAN" ]; then
    echo "⚠️ لا يوجد ملف خطة: $PLAN"
    exit 0
fi

echo "------------------------------------------"
echo "📄 خطة التنفيذ:"
tail -n +1 "$PLAN" | sed 's/^/# /'
echo "------------------------------------------"

# تنفيذ الأوامر CMD بالترتيب
while IFS= read -r line; do
    case "$line" in
        CMD\ *)
            cmd="${line#CMD }"
            echo "▶️ تنفيذ: $cmd"
            # نشغّل الأمر داخل bash عشان يدعم أي مسار أو متغيرات
            bash -lc "$cmd"
            ;;
        *)
            :
            ;;
    esac
done < "$PLAN"

echo "✅ Manager Engine انتهى من تنفيذ الخطة."
