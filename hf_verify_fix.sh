#!/usr/bin/env bash
# hf_verify_fix.sh
# التحقق من:
#  1) شكل agents_levels.json
#  2) وجود بيانات Agents في أحدث تقرير Manager
#  3) وجود agent_level في قاعدة المعرفة (إذا كانت متولدة)

set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "============================================"
echo "🔍 Hyper Factory – Verify Agents Fix"
echo "📁 ROOT : $ROOT"
echo "============================================"

echo
echo "----------- [1] فحص agents_levels.json -----------"
if [[ -f "ai/memory/people/agents_levels.json" ]]; then
  echo "✅ تم العثور على ai/memory/people/agents_levels.json"
  if command -v jq >/dev/null 2>&1; then
    echo "📊 قائمة الـ Agents (agent / level / family):"
    jq -r '.[] | "   ✅ \(.agent) | level=\(.level) | family=\(.family)"' \
      ai/memory/people/agents_levels.json || echo "⚠️ فشل jq في قراءة الملف."
  else
    echo "ℹ️ jq غير متوفر؛ عرض أول 40 سطر من الملف:"
    head -n 40 ai/memory/people/agents_levels.json || true
  fi
else
  echo "❌ ملف ai/memory/people/agents_levels.json غير موجود."
fi

echo
echo "----------- [2] فحص أحدث تقرير Manager -----------"
latest_report_txt=""
if ls reports/management/*_manager_daily_overview.txt >/dev/null 2>&1; then
  latest_report_txt=$(ls reports/management/*_manager_daily_overview.txt | sort | tail -n1)
  echo "📄 أحدث تقرير: ${latest_report_txt}"
  echo "📌 مقتطف قسم مستويات العمال الآليين:"
  grep -n "مستويات العمال الآليين" -A6 "$latest_report_txt" || echo "ℹ️ لم يتم العثور على القسم أو لا يحتوي بيانات."
else
  echo "ℹ️ لا توجد تقارير نصية في reports/management/ حتى الآن."
fi

echo
echo "----------- [3] فحص قاعدة المعرفة (knowledge.db) -----------"
DB_PATH="data/knowledge/knowledge.db"
if [[ -f "$DB_PATH" ]]; then
  if command -v sqlite3 >/dev/null 2>&1; then
    echo "📊 ملخص أنواع عناصر المعرفة المسجّلة:"
    sqlite3 "$DB_PATH" 'SELECT item_type, COUNT(*) FROM knowledge_items GROUP BY item_type;' 2>/dev/null \
      || echo "⚠️ لا يمكن قراءة جدول knowledge_items (تحقق من schema)."
  else
    echo "ℹ️ sqlite3 غير متوفر؛ يمكن مراجعته يدوياً لاحقاً: $DB_PATH"
  fi
else
  echo "ℹ️ قاعدة المعرفة غير موجودة بعد: $DB_PATH"
fi

echo
echo "✅ انتهى hf_verify_fix.sh"
