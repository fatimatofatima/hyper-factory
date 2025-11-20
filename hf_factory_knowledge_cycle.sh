#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

SPIDER_SMART="$ROOT/hf_knowledge_spider_smart_run.sh"
SPIDER_BRIDGE="$ROOT/hf_spider_items_to_tasks.sh"
PLANNER="$ROOT/hf_knowledge_tasks_planner.sh"
FACTORY_SMART="$ROOT/hf_factory_smart_run.sh"

echo "🔁 Hyper Factory – Knowledge & Quality Cycle"
echo "============================================"
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

echo "1) تشغيل Knowledge Spider Smart Run (إن وُجد)..."
if [ -x "$SPIDER_SMART" ]; then
  "$SPIDER_SMART" || echo "⚠️ انتهى hf_knowledge_spider_smart_run.sh مع تحذيرات."
else
  echo "   ℹ️ hf_knowledge_spider_smart_run.sh غير موجود – تخطى هذه الخطوة."
fi

echo ""
echo "2) تحويل صفوف العنكبوت (knowledge_items) إلى مهام فى المصنع..."
if [ -x "$SPIDER_BRIDGE" ]; then
  "$SPIDER_BRIDGE"
else
  echo "   ℹ️ hf_spider_items_to_tasks.sh غير موجود – تخطى خطوة الجسر."
fi

echo ""
echo "3) تخطيط مهام المعرفة والجودة عالية المستوى..."
if [ -x "$PLANNER" ]; then
  "$PLANNER"
else
  echo "   ℹ️ hf_knowledge_tasks_planner.sh غير موجود – لا توجد مهام معرفة إضافية."
fi

echo ""
echo "4) تشغيل Factory Smart Run لتوزيع المهام حسب الأولوية والمهارة..."
if [ -x "$FACTORY_SMART" ]; then
  "$FACTORY_SMART"
else
  echo "   ℹ️ hf_factory_smart_run.sh غير موجود – يمكنك استخدام:"
  echo "      ./hf_factory_cli.sh queue"
  echo "      ./hf_factory_cli.sh assign-next"
fi

echo ""
echo "✅ Knowledge & Quality Cycle اكتملت."
