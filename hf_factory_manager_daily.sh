#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "🏭 Hyper Factory – Daily Manager"
echo "================================"
echo "⏰ بدء المناوبة: $(date)"
echo ""

# 1. إدارة المدخلات
echo "📥 [1/6] إدارة المدخلات..."
./hf_input_manager.sh

# 2. عائلة الـ Spiders
echo "🕷️ [2/6] تشغيل عائلة الـ Spiders..."
./hf_spiders_family.sh

# 3. نظام الجودة
echo "🎯 [3/6] تشغيل نظام الجودة والأنماط..."
./hf_quality_patterns_system.sh

# 4. التشغيل التلقائي
echo "🔄 [4/6] التشغيل التلقائي الأساسي..."
./hf_full_auto_cycle.sh

# 5. إدارة الموارد
echo "💾 [5/6] إدارة الموارد..."
./hf_resource_manager.sh

# 6. التقارير النهائية
echo "📊 [6/6] إصدار التقارير..."
./hf_factory_dashboard.sh

echo ""
echo "✅ اكتملت المناوبة اليومية في: $(date)"
echo "📈 ملخص الأداء:"
sqlite3 "$ROOT/data/factory/factory.db" "
SELECT '🎯 المهام: ' || COUNT(*) || ' مهمة' FROM tasks;
SELECT '✅ المكتمل: ' || SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END) || ' مهمة' FROM tasks;
SELECT '🕷️ المعرفة: ' || COUNT(*) || ' مهمة معرفة' FROM tasks WHERE task_type = 'knowledge';
SELECT '🎯 الجودة: ' || COUNT(*) || ' مهمة جودة' FROM tasks WHERE task_type = 'quality';
SELECT '📊 الأداء: ' || ROUND(AVG(success_rate), 1) || '% معدل نجاح عام' FROM agents WHERE total_runs > 0;
"
