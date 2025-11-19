#!/usr/bin/env bash
# hf_export_owner_report.sh
# تقرير مالك Hyper Factory (قراءة فقط):
# - يلخص حالة git
# - يربط بأحدث AI Context Snapshot
# - يعرض آخر تقرير Manager
# - يلخص knowledge_items
# - يعرض ملخص المجلدات الرئيسية

set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="$ROOT/reports/ai"
mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/OWNER_${TS}_owner_report.md"
DB_PATH="$ROOT/data/knowledge/knowledge.db"

# توجيه كل المخرجات إلى الملف + الشاشة
exec > >(tee "$OUT_FILE") 2>&1

echo "# Hyper Factory – تقرير المالك (Owner Report)"
echo
echo "- Generated at (UTC): ${TS}"
echo "- Hostname: $(hostname)"
echo "- PWD: $(pwd)"
echo

########################################
# 1) حالة Git / Repository
########################################
echo "## 1) حالة Git / Repository"
echo

BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'N/A')"
LAST_COMMIT="$(git log -1 --pretty=format:'%h %s (%ci)' 2>/dev/null || echo 'N/A')"

echo "- Current branch: \`${BRANCH}\`"
echo "- Last commit   : \`${LAST_COMMIT}\`"
echo
echo "### 1.1 git status (short)"
echo
echo '```text'
git status --short 2>/dev/null || echo "⚠️ git status غير متاح"
echo '```'
echo

########################################
# 2) أحدث AI Context Snapshot
########################################
echo "## 2) أحدث AI Context Snapshot"
echo

LATEST_SNAPSHOT="$(ls -1 reports/ai/*_ai_context_snapshot.md 2>/dev/null | sort | tail -1 || true)"
if [[ -n "${LATEST_SNAPSHOT}" && -f "${LATEST_SNAPSHOT}" ]]; then
  echo "- Latest snapshot file: \`${LATEST_SNAPSHOT}\`"
else
  echo "- ⚠️ لا توجد snapshots في reports/ai/"
fi
echo

########################################
# 3) آخر تقرير Manager
########################################
echo "## 3) آخر تقرير Manager (نظرة إدارة المصنع)"
echo

LATEST_MANAGER="$(ls -1 reports/management/*_manager_daily_overview.txt 2>/dev/null | sort | tail -1 || true)"
if [[ -n "${LATEST_MANAGER}" && -f "${LATEST_MANAGER}" ]]; then
  echo "- Latest manager overview: \`${LATEST_MANAGER}\`"
  echo
  echo "### 3.1 Manager Overview (أول ~120 سطر)"
  echo
  echo '```text'
  head -n 120 "${LATEST_MANAGER}"
  echo '```'
else
  echo "- ⚠️ لا توجد تقارير Manager في reports/management/"
fi
echo

########################################
# 4) قاعدة المعرفة (knowledge_items)
########################################
echo "## 4) قاعدة المعرفة (knowledge_items)"
echo

if [[ -f "${DB_PATH}" ]]; then
  if command -v sqlite3 >/dev/null 2>&1; then
    echo "- Found knowledge DB at: \`${DB_PATH}\`"
    echo

    echo "### 4.1 Schema (PRAGMA table_info)"
    echo
    echo '```text'
    sqlite3 "${DB_PATH}" "PRAGMA table_info(knowledge_items);" || echo "⚠️ فشل قراءة schema جدول knowledge_items"
    echo '```'
    echo

    echo "### 4.2 Counts per item_type"
    echo
    echo '```text'
    sqlite3 "${DB_PATH}" "SELECT item_type, COUNT(*) FROM knowledge_items GROUP BY item_type;" || echo "⚠️ فشل قراءة counts لكل item_type"
    echo '```'
    echo

    echo "### 4.3 عينة من عناصر agent_level (حتى 10 عناصر)"
    echo
    echo '```text'
    sqlite3 "${DB_PATH}" "SELECT item_key, title, importance, tags FROM knowledge_items WHERE item_type='agent_level' ORDER BY item_key LIMIT 10;" \
      || echo "⚠️ لا توجد عناصر type=agent_level أو فشل الاستعلام"
    echo '```'
    echo
  else
    echo "- ⚠️ sqlite3 غير مثبت؛ لا يمكن فحص knowledge.db"
  fi
else
  echo "- ⚠️ لم يتم العثور على قاعدة المعرفة \`${DB_PATH}\`"
fi
echo

########################################
# 5) ملخص المجلدات الرئيسية
########################################
echo "## 5) ملخص المجلدات الرئيسية"
echo
echo "- apps/backend_coach/: Backend لخدمة مهارات / Skills."
echo "- agents/: عمال الـ Pipeline الأساسية."
echo "- scripts/core/: سكربتات تشغيل المصنع والبنية."
echo "- scripts/ai/: سكربتات AI (RAG, metrics, skills manager...)."
echo "- config/: تعريفات المصنع والـ Agents والدور."
echo "- ai/memory/: ذاكرة تشغيلية (cases, insights, lessons...)."
echo "- data/: بيانات خام/معالجة/دلالية/خدمة."
echo "- reports/: تقارير الإدارة، snapshots، diffs."
echo

echo "### 5.1 قائمة top-level من الواقع (ls -1)"
echo
echo '```text'
ls -1
echo '```'
echo

########################################
# 6) فجوات معروفة / TODO للمالك
########################################
echo "## 6) فجوات معروفة / TODO للمالك"
echo
echo "- إعداد Runbook تشغيلي (design/hf_runbook_operations.md) لضبط سلوك التشغيل اليومي."
echo "- تصميم آلية لتطبيق الدروس (knowledge_items.type=lesson) على config/agents.yaml / factory.yaml عبر hf_run_apply_lessons.sh."
echo "- إعداد تشغيل آلي عبر cron/systemd لدورات المصنع + تقارير Manager + AI Snapshots."
echo "- توثيق ربط Hyper Factory مع SmartFriend / ffactory على مستوى design أعلى."
echo
echo '---'
echo "Report written to: ${OUT_FILE}"
echo '---'
