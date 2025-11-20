#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

FACTORY_SMART="./hf_factory_smart_run.sh"
SKILLS_SMART="./hf_skills_smart_run.sh"
QUALITY_REFRESH="./hf_factory_quality_refresh.sh"

echo "🚀 Hyper Factory – Full Ops Cycle"
echo "================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

if [ -x "$FACTORY_SMART" ]; then
  echo "🔹 [1/3] تشغيل Factory Smart Run..."
  "$FACTORY_SMART"
else
  echo "⚠️ تخطّي Factory Smart Run (السكربت غير موجود أو غير قابل للتنفيذ)."
fi

echo ""
if [ -x "$SKILLS_SMART" ]; then
  echo "🔹 [2/3] تشغيل Skills Smart Run..."
  "$SKILLS_SMART"
else
  echo "⚠️ تخطّي Skills Smart Run (السكربت غير موجود أو غير قابل للتنفيذ)."
fi

echo ""
if [ -x "$QUALITY_REFRESH" ]; then
  echo "🔹 [3/3] تحديث مؤشرات الجودة (Quality Refresh)..."
  "$QUALITY_REFRESH"
else
  echo "⚠️ تخطّي Quality Refresh (السكربت غير موجود أو غير قابل للتنفيذ)."
fi

echo ""
echo "✅ Full Ops Cycle اكتملت."
