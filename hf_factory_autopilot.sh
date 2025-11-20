#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

CLI_FACTORY="$ROOT/hf_factory_cli.sh"
KNOW_CYCLE="$ROOT/hf_factory_knowledge_cycle.sh"

RUN_INGESTOR="$ROOT/hf_run_ingestor_basic.sh"
RUN_PROCESSOR="$ROOT/hf_run_processor_basic.sh"
RUN_ANALYZER="$ROOT/hf_run_analyzer_basic.sh"
RUN_REPORTER="$ROOT/hf_run_reporter_basic.sh"

PATTERNS_RUN="$ROOT/hf_run_patterns_engine.sh"
QUALITY_RUN="$ROOT/hf_run_quality_engine.sh"

LEARNING_PY="$ROOT/tools/hf_factory_learning.py"

echo "🤖 Hyper Factory – Full Autopilot Cycle"
echo "======================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

# 0) ضمان قاعدة بيانات المصنع
if [ -x "$CLI_FACTORY" ]; then
  echo "🧱 تهيئة/تحديث قاعدة بيانات المصنع (init-db)..."
  ./hf_factory_cli.sh init-db
else
  echo "❌ hf_factory_cli.sh غير موجود – لا يمكن تهيئة المصنع."
  exit 1
fi

echo ""
echo "1) تشغيل خط الإنتاج الأساسى (الكتش + المعالجة + المحلل + التقارير)..."

if [ -x "$RUN_INGESTOR" ]; then
  echo "   ▸ ingestor_basic ..."
  "$RUN_INGESTOR" || echo "   ⚠️ ingestor_basic انتهى بتحذير."
else
  echo "   ℹ️ hf_run_ingestor_basic.sh غير موجود."
fi

if [ -x "$RUN_PROCESSOR" ]; then
  echo "   ▸ processor_basic ..."
  "$RUN_PROCESSOR" || echo "   ⚠️ processor_basic انتهى بتحذير."
else
  echo "   ℹ️ hf_run_processor_basic.sh غير موجود."
fi

if [ -x "$RUN_ANALYZER" ]; then
  echo "   ▸ analyzer_basic ..."
  "$RUN_ANALYZER" || echo "   ⚠️ analyzer_basic انتهى بتحذير."
else
  echo "   ℹ️ hf_run_analyzer_basic.sh غير موجود."
fi

if [ -x "$RUN_REPORTER" ]; then
  echo "   ▸ reporter_basic ..."
  "$RUN_REPORTER" || echo "   ⚠️ reporter_basic انتهى بتحذير."
else
  echo "   ℹ️ hf_run_reporter_basic.sh غير موجود."
fi

echo ""
echo "2) دورة المعرفة والجودة (Spider ↔ Factory Manager)..."
if [ -x "$KNOW_CYCLE" ]; then
  "$KNOW_CYCLE"
else
  echo "   ℹ️ hf_factory_knowledge_cycle.sh غير موجود – تخطى هذه الخطوة."
fi

echo ""
echo "3) تشغيل أنظمة الأنماط والجودة (إن وُجدت السكربتات)..."

if [ -x "$PATTERNS_RUN" ]; then
  echo "   ▸ تشغيل محرك الأنماط..."
  "$PATTERNS_RUN" || echo "   ⚠️ محرك الأنماط انتهى بتحذير."
else
  echo "   ℹ️ hf_run_patterns_engine.sh غير موجود."
fi

if [ -x "$QUALITY_RUN" ]; then
  echo "   ▸ تشغيل محرك الجودة..."
  "$QUALITY_RUN" || echo "   ⚠️ محرك الجودة انتهى بتحذير."
else
  echo "   ℹ️ hf_run_quality_engine.sh غير موجود."
fi

echo ""
echo "4) تطبيق التعلم التلقائي من نتائج المهام (رفع Skills/إحصائيات)..."
if [ -f "$LEARNING_PY" ]; then
  python3 "$LEARNING_PY" apply || echo "   ⚠️ learning engine انتهى بتحذير."
else
  echo "   ℹ️ tools/hf_factory_learning.py غير موجود – تخطى خطوة التعلم."
fi

echo ""
echo "✅ Autopilot Cycle اكتملت."
