#!/bin/bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT" 2>/dev/null || {
  echo "❌ لا يمكن الدخول إلى $ROOT"
  exit 1
}

echo "🛠 Hyper Factory – Advanced Cycle Runner"
echo "📍 ROOT = $ROOT"
echo "⏰ $(date)"
echo "======================================="

# 1) الفحص الأساسي
echo
echo "🔍 [1/6] system_audit.sh ..."
if [ -x "./system_audit.sh" ]; then
  ./system_audit.sh || echo "⚠️ system_audit.sh أنهى مع تحذير."
else
  echo "⚠️ system_audit.sh غير موجود أو غير قابل للتنفيذ."
fi

# 2) الفحص المعماري المتقدم
echo
echo "🏗 [2/6] advanced_audit.py ..."
if [ -f "advanced_audit.py" ]; then
  python3 advanced_audit.py || echo "⚠️ advanced_audit.py أنهى مع تحذير."
else
  echo "⚠️ advanced_audit.py غير موجود."
fi

# 3) فحص الأداء
echo
echo "📈 [3/6] performance_check.py ..."
if [ -f "performance_check.py" ]; then
  python3 performance_check.py || echo "⚠️ performance_check.py أنهى مع تحذير."
else
  echo "⚠️ performance_check.py غير موجود."
fi

# 4) تشغيل محرك الأنماط
echo
echo "📊 [4/6] Patterns Engine ..."
if [ -x "./hf_run_patterns_engine.sh" ]; then
  ./hf_run_patterns_engine.sh || echo "⚠️ hf_run_patterns_engine.sh أنهى مع تحذير."
elif [ -f "agents/patterns_engine/main.py" ]; then
  python3 agents/patterns_engine/main.py || echo "⚠️ patterns_engine/main.py أنهى مع تحذير."
else
  echo "⚠️ لا يوجد محرك أنماط متاح للتشغيل."
fi

# 5) تشغيل محرك الجودة
echo
echo "🧪 [5/6] Quality Engine ..."
if [ -x "./hf_run_quality_engine.sh" ]; then
  ./hf_run_quality_engine.sh || echo "⚠️ hf_run_quality_engine.sh أنهى مع تحذير."
elif [ -f "agents/quality_engine/main.py" ]; then
  python3 agents/quality_engine/main.py || echo "⚠️ quality_engine/main.py أنهى مع تحذير."
else
  echo "⚠️ لا يوجد محرك جودة متاح للتشغيل."
fi

# 6) تشغيل الذاكرة الزمنية
echo
echo "🕒 [6/6] Temporal Memory Engine ..."
if [ -x "./hf_run_temporal_memory.sh" ]; then
  ./hf_run_temporal_memory.sh || echo "⚠️ hf_run_temporal_memory.sh أنهى مع تحذير."
elif [ -f "agents/temporal_memory/main.py" ]; then
  python3 agents/temporal_memory/main.py || echo "⚠️ temporal_memory/main.py أنهى مع تحذير."
else
  echo "⚠️ لا يوجد محرك ذاكرة زمنية متاح للتشغيل."
fi

echo
echo "======================================="
echo "📊 ملخص سريع من التقارير (إن وُجدت):"
echo "======================================="

ADV_REPORT="reports/advanced_audit.txt"
PAT_REPORT="reports/patterns/patterns_summary.txt"
QUAL_REPORT="reports/quality/knowledge_quality_report.txt"
TIMELINE="ai/memory/temporal/timeline.json"

if [ -f "$ADV_REPORT" ]; then
  echo
  echo "📄 Advanced Audit (أول 20 سطر):"
  echo "--------------------------------"
  head -n 20 "$ADV_REPORT"
else
  echo
  echo "⚠️ لا يوجد reports/advanced_audit.txt حتى الآن."
fi

if [ -f "$PAT_REPORT" ]; then
  echo
  echo "📄 Patterns Summary:"
  echo "--------------------"
  cat "$PAT_REPORT"
else
  echo
  echo "⚠️ لا يوجد reports/patterns/patterns_summary.txt حتى الآن."
fi

if [ -f "$QUAL_REPORT" ]; then
  echo
  echo "📄 Knowledge Quality Report:"
  echo "----------------------------"
  cat "$QUAL_REPORT"
else
  echo
  echo "⚠️ لا يوجد reports/quality/knowledge_quality_report.txt حتى الآن."
fi

if [ -f "$TIMELINE" ]; then
  echo
  echo "🕒 Temporal Timeline – عدد الأحداث المسجّلة:"
  echo "--------------------------------------------"
  # عدّ العناصر في JSON list بشكل بسيط
  EVENTS_COUNT=$(python3 - << 'PYEOF'
import json, sys
from pathlib import Path

p = Path("ai/memory/temporal/timeline.json")
if not p.exists():
    print(0)
    sys.exit(0)

try:
    data = json.loads(p.read_text(encoding="utf-8"))
    if isinstance(data, list):
        print(len(data))
    else:
        print(0)
except Exception:
    print(0)
PYEOF
)
  echo "🔢 الأحداث: ${EVENTS_COUNT}"
else
  echo
  echo "⚠️ لا يوجد ai/memory/temporal/timeline.json حتى الآن."
fi

echo
echo "✅ Hyper Factory – Advanced Cycle انتهت."
echo "⏰ $(date)"
