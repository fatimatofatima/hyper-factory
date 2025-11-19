#!/usr/bin/env bash
# hf_ops_master.sh
# سكربت موحّد لتشغيل دورة Hyper Factory:
# 1) (اختياري) إنشاء ملفات الأولوية (hf_create_priority_files.sh إذا موجود)
# 2) توليد Owner Report
# 3) عرض التقارير (Manager + Health + Knowledge + Snapshot)

set -euo pipefail

ROOT="/root/hyper-factory"

echo "🏭 Hyper Factory – دورة تشغيل موحّدة"
echo "===================================="
echo

if [[ -d "${ROOT}" ]]; then
  cd "${ROOT}"
else
  echo "❌ المجلد ${ROOT} غير موجود."
  exit 1
fi

ensure_script() {
  local name="$1"
  if [[ -f "${name}" ]]; then
    chmod +x "${name}" || true
    echo "✅ جاهز: ${name}"
  else
    echo "⚠️ مفقود: ${name} (لن يتم تنفيذه)"
    return 1
  fi
}

echo "🔧 فحص السكربتات المطلوبة..."
ensure_script "hf_create_priority_files.sh" || true
ensure_script "hf_export_owner_report.sh"  || true
ensure_script "hf_show_reports.sh"         || true
echo

# 1) إنشاء ملفات الأولوية (إن وُجد السكربت)
if [[ -x "./hf_create_priority_files.sh" ]]; then
  echo "▶️ [1/3] تشغيل hf_create_priority_files.sh ..."
  ./hf_create_priority_files.sh
  echo "✅ [1/3] مكتمل: إنشاء ملفات الأولوية"
else
  echo "⚠️ [1/3] تخطّي: hf_create_priority_files.sh غير موجود أو غير قابل للتنفيذ"
fi
echo

# 2) توليد Owner Report
OWNER_REPORT_PATH=""

if [[ -x "./hf_export_owner_report.sh" ]]; then
  echo "▶️ [2/3] تشغيل hf_export_owner_report.sh ..."
  ./hf_export_owner_report.sh
  OWNER_REPORT_PATH="$(ls -1 reports/ai/OWNER_*_owner_report.md 2>/dev/null | sort | tail -1 || true)"
  if [[ -n "${OWNER_REPORT_PATH}" && -f "${OWNER_REPORT_PATH}" ]]; then
    echo "✅ [2/3] تم إنشاء Owner Report:"
    echo "   ${OWNER_REPORT_PATH}"
  else
    echo "⚠️ [2/3] لم يتم العثور على Owner Report بعد التشغيل."
  fi
else
  echo "⚠️ [2/3] تخطّي: hf_export_owner_report.sh غير موجود أو غير قابل للتنفيذ"
fi
echo

# 3) عرض التقارير (إن وُجد hf_show_reports.sh)
if [[ -x "./hf_show_reports.sh" ]]; then
  echo "▶️ [3/3] تشغيل hf_show_reports.sh (عرض التقارير)..."
  ./hf_show_reports.sh
  echo "✅ [3/3] مكتمل: تم عرض التقارير على الشاشة"
else
  echo "⚠️ [3/3] تخطّي: hf_show_reports.sh غير موجود أو غير قابل للتنفيذ"
fi
echo

echo "📌 ملخّص:"
if [[ -n "${OWNER_REPORT_PATH:-}" ]]; then
  echo "- آخر Owner Report: ${OWNER_REPORT_PATH}"
fi

LATEST_MANAGER="$(ls -1 reports/management/*_manager_daily_overview.txt 2>/dev/null | sort | tail -1 || true)"
if [[ -n "${LATEST_MANAGER}" ]]; then
  echo "- آخر Manager Overview: ${LATEST_MANAGER}"
fi

LATEST_SNAPSHOT="$(ls -1 reports/ai/*_ai_context_snapshot.md 2>/dev/null | sort | tail -1 || true)"
if [[ -n "${LATEST_SNAPSHOT}" ]]; then
  echo "- آخر AI Context Snapshot: ${LATEST_SNAPSHOT}"
fi

echo
echo "🎯 تشغيل تشغيلي إضافي (اختياري):"
echo "   ./run_basic_with_memory.sh        # تشغيل دورة المصنع"
echo "   ./hf_run_manager_dashboard.sh     # تحديث تقارير الإدارة"
echo "   ./scripts/core/health_monitor.sh  # فحص صحة النظام"
echo
echo "✅ دورة hf_ops_master.sh اكتملت."
