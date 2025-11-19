#!/usr/bin/env bash
# سكربت عرض التقارير على الشاشة مباشرة

set -euo pipefail

echo "📊 عرض تقارير Hyper Factory المباشرة"
echo "======================================"
echo

# 1. آخر تقرير Manager
echo "1. 📋 آخر تقرير Manager:"
echo "------------------------"
latest_manager=$(find reports/management -name "*_manager_daily_overview.txt" -type f | sort | tail -1)
if [[ -n "$latest_manager" && -f "$latest_manager" ]]; then
    echo "📁 الملف: $latest_manager"
    echo
    cat "$latest_manager"
else
    echo "⚠️ لا توجد تقارير manager"
fi
echo

# 2. حالة الصحة
echo "2. 🩺 حالة الصحة:"
echo "-----------------"
if [[ -f "reports/health_check_report.json" ]]; then
    echo "📁 الملف: reports/health_check_report.json"
    echo
    cat "reports/health_check_report.json" | head -20
else
    echo "⚠️ لا يوجد تقرير صحة حديث"
fi
echo

# 3. قاعدة المعرفة
echo "3. 🧠 قاعدة المعرفة:"
echo "--------------------"
if [[ -f "data/knowledge/knowledge.db" ]]; then
    echo "📊 إحصائيات knowledge_items:"
    sqlite3 data/knowledge/knowledge.db "SELECT item_type, COUNT(*) FROM knowledge_items GROUP BY item_type;" 2>/dev/null || echo "❌ خطأ في قراءة DB"
    echo
    echo "📋 آخر agent_level items:"
    sqlite3 data/knowledge/knowledge.db "SELECT item_key, title FROM knowledge_items WHERE item_type='agent_level' LIMIT 10;" 2>/dev/null || echo "❌ خطأ في قراءة DB"
else
    echo "⚠️ قاعدة المعرفة غير موجودة"
fi
echo

# 4. العمال والمستويات
echo "4. 👥 العمال والمستويات:"
echo "------------------------"
if [[ -f "ai/memory/people/agents_levels.json" ]]; then
    echo "📁 الملف: ai/memory/people/agents_levels.json"
    echo
    if command -v jq >/dev/null 2>&1; then
        jq '.' "ai/memory/people/agents_levels.json" | head -20
    else
        cat "ai/memory/people/agents_levels.json" | head -10
    fi
else
    echo "⚠️ ملف agents_levels.json غير موجود"
fi
echo

# 5. آخر AI Context Snapshot
echo "5. 🤖 آخر AI Context Snapshot:"
echo "-----------------------------"
latest_snapshot=$(find reports/ai -name "*_ai_context_snapshot.md" -type f | sort | tail -1)
if [[ -n "$latest_snapshot" && -f "$latest_snapshot" ]]; then
    echo "📁 الملف: $latest_snapshot"
    echo
    echo "📋 محتوى مختصر:"
    grep -E "^(## |### |- |# )" "$latest_snapshot" | head -15
else
    echo "⚠️ لا توجد snapshots"
fi
echo

# 6. حالة Git
echo "6. 🔄 حالة Git:"
echo "--------------"
git status --short 2>/dev/null || echo "⚠️ لا يمكن قراءة حالة git"
echo

# 7. السكربتات المتاحة
echo "7. ⚡ السكربتات المتاحة:"
echo "-----------------------"
echo "🔹 سكربتات hf_run_*:"
ls hf_run_*.sh 2>/dev/null | head -8 || echo "⚠️ لا توجد سكربتات hf_run"
echo
echo "🔹 سكربتات hf_* الأخرى:"
ls hf_*.sh 2>/dev/null | grep -v "hf_run_" | head -8 || echo "⚠️ لا توجد سكربتات hf أخرى"

echo
echo "======================================"
echo "🎯 أوامر سريعة للتشغيل:"
echo "   ./run_basic_with_memory.sh     - تشغيل المصنع"
echo "   ./hf_run_manager_dashboard.sh  - تحديث التقارير"
echo "   ./scripts/core/health_monitor.sh - فحص الصحة"
echo "   ./hf_export_ai_context.sh      - إنشاء snapshot جديد"
