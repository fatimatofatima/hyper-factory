#!/usr/bin/env bash
# run_basic_with_memory.sh
# يشغّل:
# 1) run_basic_with_report.sh  (pipeline كامل + summary)
# 2) hf_log_last_run.sh        (تسجيل آخر دورة في الذاكرة)
# 3) tools/hf_build_insights.py (بناء insights + quality)

set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "🚀 تشغيل دورة Hyper Factory (pipeline + report + memory)..."
echo "----------------------------------------"

# 1) pipeline + report
if [[ ! -x "$ROOT/run_basic_with_report.sh" ]]; then
  echo "❌ run_basic_with_report.sh غير موجود أو غير قابل للتنفيذ."
  exit 1
fi
"$ROOT/run_basic_with_report.sh"

# 2) تسجيل آخر دورة في الذاكرة
if [[ ! -x "$ROOT/hf_log_last_run.sh" ]]; then
  echo "❌ hf_log_last_run.sh غير موجود أو غير قابل للتنفيذ."
  exit 1
fi
echo
echo "🧠 تسجيل آخر دورة في ai/memory/messages.jsonl ..."
"$ROOT/hf_log_last_run.sh"

# 3) بناء insights + quality
if [[ ! -f "$ROOT/tools/hf_build_insights.py" ]]; then
  echo "❌ tools/hf_build_insights.py غير موجود."
  exit 1
fi
echo
echo "📊 بناء insights + quality من الذاكرة..."
python3 "$ROOT/tools/hf_build_insights.py"

echo
echo "✅ انتهى التشغيل + التعلّم."
echo "   - ai/memory/messages.jsonl"
echo "   - ai/memory/insights.json"
echo "   - ai/memory/insights.txt"
echo "   - ai/memory/quality.json"
