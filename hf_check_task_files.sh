#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${ROOT_DIR}/reports/diagnostics"
mkdir -p "${REPORT_DIR}"

NOW="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="${REPORT_DIR}/hf_tasks_check_${NOW}.txt"

DB_PATH="${ROOT_DIR}/data/knowledge/knowledge.db"

echo "Hyper Factory – Task & Knowledge Tasks Check (${NOW})" | tee "${REPORT_FILE}"
echo "======================================================" | tee -a "${REPORT_FILE}"
echo "ROOT: ${ROOT_DIR}" | tee -a "${REPORT_FILE}"
echo | tee -a "${REPORT_FILE}"

#############################
# 1) فحص ملفات المهام / المسارات / الدروس
#############################

declare -a FILES=(
  "skills_rules|config/skills_task_rules.yaml|قواعد ربط المهارات بالمهام"
  "tracks_backend|config/skills_tracks_backend.yaml|مسارات المهارات (نسخة تشغيلية)"
  "tracks_complete|config/skills_tracks_backend_complete.yaml|مسارات المهارات (نسخة كاملة)"
  "smart_actions|ai/memory/smart_actions.json|أوامر ذكية (Smart Actions)"
  "autonomous_schedule|ai/memory/autonomous_schedule.json|جدولة ذاتية للمهام"
  "learning_lessons|ai/memory/learning_lessons.json|دروس / وحدات تدريبية"
)

echo "1) فحص ملفات المهام / المسارات / الدروس" | tee -a "${REPORT_FILE}"
echo "-----------------------------------------" | tee -a "${REPORT_FILE}"

for item in "${FILES[@]}"; do
  IFS='|' read -r key relpath desc <<< "${item}"
  full="${ROOT_DIR}/${relpath}"

  if [[ -f "${full}" ]]; then
    size=$(stat -c%s "${full}" 2>/dev/null || echo 0)
    if [[ "${size}" -gt 0 ]]; then
      echo "- ${key}: 🟢 موجود (غير فارغ) → ${relpath} | ${desc}" | tee -a "${REPORT_FILE}"
    else
      echo "- ${key}: ⚠️ موجود لكن فارغ → ${relpath} | ${desc}" | tee -a "${REPORT_FILE}"
    fi
  else
    echo "- ${key}: 🔴 غير موجود → ${relpath} | ${desc}" | tee -a "${REPORT_FILE}"
  fi
done

echo | tee -a "${REPORT_FILE}"

#############################
# 2) فحص جداول المهام والمعرفة في DB
#############################

echo "2) فحص جداول المعرفة / المهام داخل قاعدة البيانات" | tee -a "${REPORT_FILE}"
echo "--------------------------------------------------" | tee -a "${REPORT_FILE}"

if [[ ! -f "${DB_PATH}" ]]; then
  echo "🔴 قاعدة المعرفة غير موجودة: ${DB_PATH}" | tee -a "${REPORT_FILE}"
  echo "شغّل: ./hf_db_core_init.sh ثم ./hf_register_agents_from_yaml.sh" | tee -a "${REPORT_FILE}"
  exit 0
fi

echo "🗃️ DB: ${DB_PATH}" | tee -a "${REPORT_FILE}"

check_table() {
  local tbl="$1"
  local label="$2"
  local c

  c=$(sqlite3 "${DB_PATH}" "SELECT COUNT(*) FROM ${tbl};" 2>/dev/null || echo "ERR")

  if [[ "${c}" == "ERR" ]]; then
    echo "- ${label} (${tbl}): 🔴 جدول غير موجود" | tee -a "${REPORT_FILE}"
  else
    if [[ "${c}" -gt 0 ]]; then
      echo "- ${label} (${tbl}): 🟢 ${c} سجل" | tee -a "${REPORT_FILE}"
    else
      echo "- ${label} (${tbl}): ⚠️ موجود لكن بدون سجلات" | tee -a "${REPORT_FILE}"
    fi
  fi
}

# حالة جدول العمال (العوامل المتقدمة / البنية التحتية)
check_table "agents"                  "جداول العمال (Agents Registry)"

# جداول المعرفة/الجودة/الأنماط (من التقارير التي ظهرت في اللوج)
check_table "knowledge_items"         "عناصر معرفة أساسية"
check_table "web_knowledge"           "معرفة من الويب"
check_table "programming_patterns"    "أنماط برمجية"
check_table "debug_solutions"         "حلول تصحيح"
check_table "training_recommendations" "توصيات تدريب"
check_table "performance_evaluations" "تقييمات أداء"
check_table "system_patterns"         "أنماط تشغيلية للنظام"
check_table "agent_memory"            "ذاكرة العوامل (Agent Memory)"
check_table "knowledge_snapshots"     "لقطات معرفة زمنية"
check_table "db_health_reports"       "تقارير صحة قاعدة البيانات"
check_table "schema_review_reports"   "تقارير مراجعة المخطط"
check_table "knowledge_linking_reports" "تقارير ربط المعرفة"

echo | tee -a "${REPORT_FILE}"

#############################
# 3) ملخص سريع
#############################

echo "3) ملخص سريع" | tee -a "${REPORT_FILE}"
echo "-------------" | tee -a "${REPORT_FILE}"

# عدد العمال المسجّلين فعليًا
AGENTS_COUNT=$(sqlite3 "${DB_PATH}" "SELECT COUNT(*) FROM agents;" 2>/dev/null || echo 0)
echo "- عدد العمال المسجّلين في agents: ${AGENTS_COUNT}" | tee -a "${REPORT_FILE}"

echo | tee -a "${REPORT_FILE}"
echo "✅ تم حفظ التقرير في: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
