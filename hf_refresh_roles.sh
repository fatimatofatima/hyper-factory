#!/usr/bin/env bash
# hf_refresh_roles.sh
# إعادة تشغيل محرك الأدوار والكوتش والـ Dashboard والـ Knowledge Spider
# (لا يكتب JSON بنفسه، فقط يستخدم الـ Hotfix لو موجود)

set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "============================================"
echo "🔄 Hyper Factory – Refresh Roles & Manager"
echo "📁 ROOT : $ROOT"
echo "============================================"

# 0) لو موجود سكربت إصلاح الـ Agents شغّله أولاً (اختياري لكن مفيد)
if [[ -x "tools/hf_fix_agents_data.py" ]]; then
  echo "🔧 تشغيل Hotfix: tools/hf_fix_agents_data.py"
  python3 tools/hf_fix_agents_data.py
else
  echo "ℹ️ لا يوجد tools/hf_fix_agents_data.py (يمكن إنشاؤه لاحقاً إذا احتجت)."
fi

echo
echo "--------------------------------------------"
echo "1) تشغيل محرك الأدوار hf_run_roles_engine.sh"
echo "--------------------------------------------"
if [[ -x "./hf_run_roles_engine.sh" ]]; then
  ./hf_run_roles_engine.sh || echo "⚠️ hf_run_roles_engine.sh انتهى بخطأ، راجع اللوج."
else
  echo "⚠️ hf_run_roles_engine.sh غير موجود أو غير قابل للتنفيذ."
fi

echo
echo "--------------------------------------------"
echo "2) تشغيل المدرب التقني hf_run_technical_coach.sh"
echo "--------------------------------------------"
if [[ -x "./hf_run_technical_coach.sh" ]]; then
  ./hf_run_technical_coach.sh || echo "⚠️ hf_run_technical_coach.sh انتهى بخطأ، راجع اللوج."
else
  echo "ℹ️ hf_run_technical_coach.sh غير موجود (ليس إجباري)."
fi

echo
echo "--------------------------------------------"
echo "3) تشغيل Manager Dashboard"
echo "--------------------------------------------"
if [[ -x "./hf_run_manager_dashboard.sh" ]]; then
  ./hf_run_manager_dashboard.sh || echo "⚠️ hf_run_manager_dashboard.sh انتهى بخطأ، راجع اللوج."
else
  echo "ℹ️ hf_run_manager_dashboard.sh غير موجود."
fi

echo
echo "--------------------------------------------"
echo "4) تشغيل Knowledge Spider (إن وجد)"
echo "--------------------------------------------"
if [[ -x "./hf_run_knowledge_spider.sh" ]]; then
  ./hf_run_knowledge_spider.sh || echo "⚠️ hf_run_knowledge_spider.sh انتهى بخطأ، راجع اللوج."
else
  echo "ℹ️ hf_run_knowledge_spider.sh غير موجود."
fi

echo
echo "--------------------------------------------"
echo "5) معاينة ملف agents_levels.json (بعد التحديث)"
echo "--------------------------------------------"
if [[ -f "ai/memory/people/agents_levels.json" ]]; then
  echo "📄 ai/memory/people/agents_levels.json (مقتطف):"
  head -n 80 ai/memory/people/agents_levels.json || true
else
  echo "⚠️ ملف agents_levels.json غير موجود بعد التحديث."
fi

echo
echo "✅ انتهى hf_refresh_roles.sh"
