#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="${ROOT_DIR}/reports/diagnostics"
mkdir -p "${REPORT_DIR}"

NOW="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="${REPORT_DIR}/hf_tasks_check_${NOW}.txt"

echo "Hyper Factory – Task Files Check (${NOW})" | tee "${REPORT_FILE}"
echo "==========================================" | tee -a "${REPORT_FILE}"
echo "ROOT: ${ROOT_DIR}" | tee -a "${REPORT_FILE}"
echo >> "${REPORT_FILE}"

# 1) ملفات المهام/المسارات/الدروس المتوقعة
declare -a FILES=(
  "skills_rules|config/skills_task_rules.yaml|قواعد ربط المهارات بالمهام"
  "tracks_complete|config/skills_tracks_backend_complete.yaml|مسارات المهارات الكاملة"
  "tracks_backend|config/skills_tracks_backend.yaml|مسارات المهارات (نسخة مختصرة)"
  "smart_actions|ai/memory/smart_actions.json|مهام/أوامر ذكية (Smart Actions)"
  "autonomous_schedule|ai/memory/autonomous_schedule.json|جدول المهام الذاتية (Autonomous Schedule)"
  "quality_status|ai/memory/quality_status.json|ملف حالة الجودة المرتبط بالمهام"
  "lessons_plan|reports/management/lessons_apply_plan.md|خطة تطبيق الدروس (Lessons Apply Plan)"
  "lessons_report|reports/management/lessons_export_report.txt|تقرير تصدير الدروس/المهام"
)

echo "1) فحص ملفات المهام الأساسية" | tee -a "${REPORT_FILE}"
echo "------------------------------------------" | tee -a "${REPORT_FILE}"

FOUND=0
MISSING=0

for entry in "${FILES[@]}"; do
  IFS='|' read -r KEY REL_PATH DESC <<<"${entry}"
  ABS_PATH="${ROOT_DIR}/${REL_PATH}"

  if [[ -f "${ABS_PATH}" ]]; then
    SIZE_BYTES=$(stat -c '%s' "${ABS_PATH}" 2>/dev/null || echo "?")
    MTIME=$(stat -c '%y' "${ABS_PATH}" 2>/dev/null || echo "?")
    ((FOUND++))

    echo "✅ ${KEY}" | tee -a "${REPORT_FILE}"
    echo "   • الوصف : ${DESC}"       | tee -a "${REPORT_FILE}"
    echo "   • المسار : ${REL_PATH}" | tee -a "${REPORT_FILE}"
    echo "   • الحجم  : ${SIZE_BYTES} bytes" | tee -a "${REPORT_FILE}"
    echo "   • آخر تعديل: ${MTIME}" | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
  else
    ((MISSING++))
    echo "❌ ${KEY}" | tee -a "${REPORT_FILE}"
    echo "   • الوصف : ${DESC}"       | tee -a "${REPORT_FILE}"
    echo "   • المسار : ${REL_PATH}" | tee -a "${REPORT_FILE}"
    echo "   • الحالة: مفقود"        | tee -a "${REPORT_FILE}"
    echo "" | tee -a "${REPORT_FILE}"
  fi
done

echo "ملخص الملفات الأساسية:"      | tee -a "${REPORT_FILE}"
echo "   ✅ موجود   : ${FOUND}"     | tee -a "${REPORT_FILE}"
echo "   ❌ مفقود   : ${MISSING}"   | tee -a "${REPORT_FILE}"
echo "" | tee -a "${REPORT_FILE}"

# 2) بحث عن أي ملفات إضافية لها علاقة بـ tasks / lessons / todo
echo "2) بحث عن ملفات مهام/دروس إضافية (config / ai / reports)" | tee -a "${REPORT_FILE}"
echo "---------------------------------------------------------" | tee -a "${REPORT_FILE}"

EXTRA_FOUND=0
while IFS= read -r f; do
  [[ -z "${f}" ]] && continue
  ((EXTRA_FOUND++))
  REL="${f#${ROOT_DIR}/}"
  SIZE_BYTES=$(stat -c '%s' "${f}" 2>/dev/null || echo "?")
  MTIME=$(stat -c '%y' "${f}" 2>/dev/null || echo "?")

  echo "🔎 ${REL}" | tee -a "${REPORT_FILE}"
  echo "   • الحجم  : ${SIZE_BYTES} bytes" | tee -a "${REPORT_FILE}"
  echo "   • آخر تعديل: ${MTIME}"         | tee -a "${REPORT_FILE}"
  echo "" | tee -a "${REPORT_FILE}"
done < <(find "${ROOT_DIR}/config" "${ROOT_DIR}/ai" "${ROOT_DIR}/reports" \
           -type f \( -iname '*task*' -o -iname '*tasks*' -o -iname '*lesson*' -o -iname '*todo*' \) 2>/dev/null)

if [[ "${EXTRA_FOUND}" -eq 0 ]]; then
  echo "لا توجد ملفات إضافية لها أسماء مرتبطة بالمهام/الدروس/todo في المسارات المفحوصة." | tee -a "${REPORT_FILE}"
fi

echo "" | tee -a "${REPORT_FILE}"
echo "تم حفظ التقرير في: ${REPORT_FILE}" | tee -a "${REPORT_FILE}"
