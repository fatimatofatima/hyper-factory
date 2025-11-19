#!/usr/bin/env bash
# hf_diag_manager_and_roles.sh
# فحص حالة تقارير الأداء + أدوار الـ Agents + الربط مع Manager Dashboard
# بدون أي تعديل على الملفات

set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "===================== [1] Git / Repo State ====================="
echo "📌 المسار  : $ROOT"
echo "📌 الريموت :"
git remote -v || echo "⚠️ لا يمكن قراءة git remote"

echo
echo "📌 آخر commit على هذا السيرفر:"
git log -1 --oneline || echo "⚠️ لا يمكن قراءة git log"

echo
echo "📌 git status (مختصر):"
git status --short || echo "⚠️ لا يمكن قراءة git status"

echo
echo "===================== [2] summary_basic.json ===================="
if [[ -f "data/report/summary_basic.json" ]]; then
  echo "✅ تم العثور على data/report/summary_basic.json"
  if command -v jq >/dev/null 2>&1; then
    echo "--- المفاتيح الموجودة في summary_basic.json ---"
    jq 'keys' data/report/summary_basic.json || echo "⚠️ jq فشل في قراءة الملف"
    echo
    echo "--- محتوى مختصر (بدون إغراق) ---"
    jq '{total_runs, success_runs, failed_runs, days_observed, avg_success_rate}' \
      data/report/summary_basic.json 2>/dev/null || \
      jq '.' data/report/summary_basic.json
  else
    echo "ℹ️ jq غير مثبت؛ عرض الملف خام:"
    head -n 80 data/report/summary_basic.json
  fi
else
  echo "❌ ملف data/report/summary_basic.json غير موجود"
fi

echo
echo "===================== [3] agents_levels.json ===================="
if [[ -f "ai/memory/people/agents_levels.json" ]]; then
  echo "✅ تم العثور على ai/memory/people/agents_levels.json"
  if command -v jq >/dev/null 2>&1; then
    echo "--- أسماء الـ Agents كما هي في JSON (مختصرة) ---"
    jq '.agents // . | to_entries
        | map({agent: .key,
               family: (.value.family // "missing"),
               display_name: (.value.display_name // .key),
               level: (.value.level // "missing"),
               salary_index: (.value.salary_index // "missing")})' \
        ai/memory/people/agents_levels.json 2>/dev/null || \
        jq '.' ai/memory/people/agents_levels.json
  else
    echo "ℹ️ jq غير مثبت؛ عرض الملف خام (أول 120 سطر):"
    head -n 120 ai/memory/people/agents_levels.json
  fi
else
  echo "❌ ملف ai/memory/people/agents_levels.json غير موجود"
fi

echo
echo "===================== [4] config/roles.json ====================="
if [[ -f "config/roles.json" ]]; then
  echo "✅ تم العثور على config/roles.json (عرض أول 80 سطر):"
  head -n 80 config/roles.json
else
  echo "❌ ملف config/roles.json غير موجود"
fi

echo
echo "===================== [5] مواضع 'unknown' في الكود ============="
for f in tools/hf_manager_dashboard.py tools/hf_roles_engine.py; do
  if [[ -f "$f" ]]; then
    echo
    echo "----- $f -----"
    grep -n "unknown" "$f" || echo "ℹ️ لا توجد كلمة 'unknown' في $f"
  else
    echo "⚠️ الملف غير موجود: $f"
  fi
done

echo
echo "===================== [6] آخر تقرير Manager Dashboard ========="
if ls reports/management/*_manager_daily_overview.txt >/dev/null 2>&1; then
  latest=$(ls reports/management/*_manager_daily_overview.txt | sort | tail -n1)
  echo "📄 أحدث تقرير: $latest"
  echo "---------------------------------------------------------------"
  tail -n 80 "$latest"
else
  echo "ℹ️ لا توجد تقارير في reports/management حتى الآن."
fi

echo
echo "✅ انتهى hf_diag_manager_and_roles.sh (فحص فقط بدون أي تعديل)."
