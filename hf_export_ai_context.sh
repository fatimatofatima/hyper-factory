#!/usr/bin/env bash
# hf_export_ai_context.sh
# تصدير "صورة سياقية" كاملة لمصنع Hyper Factory من السيرفر:
# - لا يعدّل أي شيء (قراءة فقط)
# - ينتج تقرير Markdown داخل reports/ai/
# - الهدف: إعطاء أي نموذج جديد صورة واضحة عن:
#   * حالة الكود (git)
#   * بنية المجلدات
#   * حالة الـ Agents
#   * حالة قاعدة المعرفة
#   * آخر تقارير الإدارة

set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="$ROOT/reports/ai"
mkdir -p "$OUT_DIR"
OUT_FILE="$OUT_DIR/${TS}_ai_context_snapshot.md"

# كل المخرجات تذهب إلى الملف + تظهر على الشاشة
exec > >(tee "$OUT_FILE") 2>&1

echo "# Hyper Factory – AI Context Snapshot"
echo
echo "- Generated at (UTC): ${TS}"
echo "- Hostname: $(hostname)"
echo "- PWD: $(pwd)"
echo

###############################################
echo "## 1) Git / Repository State"
echo
echo "### 1.1 Remotes"
git remote -v 2>/dev/null || echo "_no git remotes_"
echo

echo "### 1.2 Branches"
git branch -vv 2>/dev/null || echo "_no branches info_"
echo

echo "### 1.3 git status (short)"
git status --short 2>/dev/null || echo "_cannot read git status_"
echo

###############################################
echo "## 2) Project Layout (Top Folders)"
echo

for d in apps scripts agents config design ai data reports; do
  if [[ -d "$d" ]]; then
    echo "### 2.x Folder: \`$d/\`"
    # عرض الملفات من عمقين فقط لتقليل الإغراق
    find "$d" -maxdepth 2 -type f | sort | head -n 60 || true
    echo
  fi
done

###############################################
echo "## 3) Design & Documentation Files"
echo

if [[ -d "design" ]]; then
  echo "### 3.1 design/*.md"
  find design -maxdepth 2 -type f -name "*.md" | sort || echo "_no design/*.md_"
  echo

  echo "### 3.2 design/*.pdf"
  find design -maxdepth 2 -type f -name "*.pdf" | sort || echo "_no design/*.pdf_"
  echo
else
  echo "_no design directory_"
  echo
fi

echo "### 3.3 Root-level README / docs"
ls -1 README* *.md 2>/dev/null || echo "_no root-level markdown docs_"
echo

###############################################
echo "## 4) Agents & Roles"
echo

AGENTS_JSON="ai/memory/people/agents_levels.json"
if [[ -f "$AGENTS_JSON" ]]; then
  echo "- Found agents_levels.json at: \`$AGENTS_JSON\`"
  if command -v jq >/dev/null 2>&1; then
    echo
    echo "### 4.1 Agents Snapshot (from agents_levels.json)"
    # عرض ملخص لكل Agent
    jq -r '.[] | " - agent=\(.agent) | level=\(.level) | family=\(.family) | success_rate=\(.success_rate)"' \
      "$AGENTS_JSON" 2>/dev/null || echo "_failed to parse agents_levels.json_"
  else
    echo "_jq not available; showing raw JSON head:_"
    echo '```json'
    head -n 60 "$AGENTS_JSON" || true
    echo '```'
  fi
else
  echo "- No agents_levels.json found at: $AGENTS_JSON"
fi
echo

###############################################
echo "## 5) Knowledge Database (knowledge.db)"
echo

DB_PATH="data/knowledge/knowledge.db"
if [[ -f "$DB_PATH" ]]; then
  echo "- Found knowledge DB at: \`$DB_PATH\`"
  if command -v sqlite3 >/dev/null 2>&1; then
    echo
    echo "### 5.1 Schema of table knowledge_items"
    sqlite3 "$DB_PATH" 'PRAGMA table_info(knowledge_items);' 2>/dev/null || echo "_cannot read schema_"
    echo

    echo "### 5.2 Counts per item_type"
    sqlite3 "$DB_PATH" 'SELECT item_type, COUNT(*) FROM knowledge_items GROUP BY item_type;' 2>/dev/null || echo "_cannot select item_type counts_"
    echo

    echo "### 5.3 Sample of agent_level items (if any)"
    sqlite3 "$DB_PATH" "SELECT item_key, title, importance, tags FROM knowledge_items WHERE item_type='agent_level' LIMIT 20;" 2>/dev/null || echo "_no agent_level items or cannot query_"
    echo
  else
    echo "_sqlite3 not available; cannot introspect DB._"
    echo
  fi
else
  echo "- knowledge.db not found at: $DB_PATH"
  echo
fi

###############################################
echo "## 6) Latest Manager / Dashboard Reports"
echo

MG_DIR="reports/management"
if [[ -d "$MG_DIR" ]]; then
  LAST_TXT="$(ls -1 ${MG_DIR}/*_manager_daily_overview.txt 2>/dev/null | sort | tail -n 1 || true)"
  if [[ -n "${LAST_TXT}" && -f "${LAST_TXT}" ]]; then
    echo "- Latest manager overview TXT: \`${LAST_TXT}\`"
    echo
    echo "### 6.1 Manager Overview (first ~120 lines)"
    echo '```text'
    sed -n '1,120p' "${LAST_TXT}" || true
    echo '```'
  else
    echo "_no manager_daily_overview.txt reports found_"
  fi
  echo
else
  echo "- No reports/management directory."
  echo
fi

###############################################
echo "## 7) Run Scripts Inventory (hf_run_*.sh)"
echo

ls -1 hf_run_*.sh 2>/dev/null || echo "_no hf_run_*.sh scripts at root_"
echo

echo "### 7.1 Other helper scripts (hf_*.sh)"
ls -1 hf_*.sh 2>/dev/null | grep -v 'hf_run_' || echo "_no extra hf_*.sh scripts_"
echo

###############################################
echo "## 8) Environment / Config Templates"
echo

echo "### 8.1 config files (json/yaml/yml)"
find config -maxdepth 2 -type f \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | sort || echo "_no config json/yaml files_"
echo

echo "### 8.2 .env templates (if any)"
find . -maxdepth 2 -type f -name ".env*" 2>/dev/null | sort || echo "_no .env templates found_"
echo

###############################################
echo "## 9) Summary for AI / Next Model"
echo
echo "- This snapshot is auto-generated from server-side real state."
echo "- It is safe (read-only) and does not modify DB or services."
echo "- Use this file as the first entry point to understand:"
echo "  * what exists (code, agents, knowledge, reports)"
echo "  * what is already running conceptually"
echo "  * where to add new runbooks or roadmaps if missing."
echo
echo "---"
echo "Snapshot file written to: ${OUT_FILE}"
echo "---"
