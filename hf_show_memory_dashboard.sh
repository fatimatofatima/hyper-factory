#!/usr/bin/env bash
# hf_show_memory_dashboard.sh
# عرض لوحة ذاكرة Hyper Factory (CLI Dashboard)

set -euo pipefail

ROOT="/root/hyper-factory"
MEMORY_DIR="$ROOT/ai/memory"
QUALITY_JSON="$MEMORY_DIR/quality.json"
INSIGHTS_JSON="$MEMORY_DIR/insights.json"
MESSAGES_JSONL="$MEMORY_DIR/messages.jsonl"

echo "📁 ROOT        : $ROOT"
echo "📂 MEMORY_DIR  : $MEMORY_DIR"
echo "----------------------------------------"

cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 غير متوفر في PATH."
  exit 1
fi

echo
echo "===== 1) QUALITY (ai/memory/quality.json) ====="
if [[ -f "$QUALITY_JSON" ]]; then
  python3 -m json.tool "$QUALITY_JSON"
else
  echo "ℹ️ لا يوجد quality.json بعد. شغّل hf_build_insights.py أو run_basic_with_memory.sh."
fi

echo
echo "===== 2) INSIGHTS (ai/memory/insights.json) ====="
if [[ -f "$INSIGHTS_JSON" ]]; then
  python3 -m json.tool "$INSIGHTS_JSON"
else
  echo "ℹ️ لا يوجد insights.json بعد. شغّل hf_build_insights.py أو run_basic_with_memory.sh."
fi

echo
echo "===== 3) آخر 10 أحداث من messages.jsonl ====="
if [[ -f "$MESSAGES_JSONL" ]]; then
  tail -n 10 "$MESSAGES_JSONL"
else
  echo "ℹ️ لا يوجد messages.jsonl بعد. شغّل hf_log_last_run.sh بعد أول دورة."
fi

echo
echo "✅ انتهى عرض لوحة الذاكرة."
