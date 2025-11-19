#!/usr/bin/env bash
# Hyper Factory – Brain Diagnostic (Read-only)
# Usage:
#   ./hf_diag_brain.sh              # يفترض /root/hyper-factory
#   ./hf_diag_brain.sh /path/to/hyper-factory

set -u
set -o pipefail

ROOT="${1:-/root/hyper-factory}"

section() {
  echo
  echo "=================================================="
  echo "$1"
  echo "=================================================="
}

status_line() {
  local label="$1"
  local state="$2"
  echo "- [$state] $label"
}

short_path() {
  local p="$1"
  echo "${p#"$ROOT"/}"
}

section "1) تعريف بيئة Hyper Factory"
echo "ROOT: $ROOT"
if [ ! -d "$ROOT" ]; then
  echo "❌ المسار غير موجود: $ROOT"
  exit 1
fi

cd "$ROOT"

# -----------------------------
section "2) فحص البنية الأساسية (Folders & Core Files)"

DIRS=("agents" "config" "ai" "data" "reports")
for d in "${DIRS[@]}"; do
  if [ -d "$d" ]; then
    status_line "المجلد $(short_path "$d")" "OK"
  else
    status_line "المجلد $(short_path "$d")" "MISSING"
  fi
done

CORE_FILES=(
  "config/factory.yaml"
  "config/agents.yaml"
  "config/orchestrator.yaml"
  "data/knowledge/knowledge.db"
)
for f in "${CORE_FILES[@]}"; do
  if [ -f "$f" ]; then
    status_line "الملف $(short_path "$f")" "OK"
  else
    status_line "الملف $(short_path "$f")" "MISSING"
  fi
done

# -----------------------------
section "3) فحص خط الإنتاج (Pipeline: RAW → PROCESSED → SEMANTIC → SERVING)"

RAW_COUNT=$(ls data/raw/*.txt 2>/dev/null | wc -l | tr -d ' ')
PROC_COUNT=$(ls data/processed/*.meta.txt 2>/dev/null | wc -l | tr -d ' ')
SEM_COUNT=$(ls data/semantic/*.semantic.json 2>/dev/null | wc -l | tr -d ' ')
SERV_FILE="data/serving/semantic_serving_summary.json"

echo "📦 RAW       (data/raw/*.txt)             : $RAW_COUNT ملف"
echo "📦 PROCESSED (data/processed/*.meta.txt)  : $PROC_COUNT ملف"
echo "📦 SEMANTIC  (data/semantic/*.semantic.json): $SEM_COUNT ملف"

if [ -f "$SERV_FILE" ]; then
  status_line "ملف الخدمة $(short_path "$SERV_FILE")" "OK"
else
  status_line "ملف الخدمة $(short_path "$SERV_FILE")" "MISSING"
fi

# تقييم عام بسيط
if [ "$RAW_COUNT" -gt 0 ] && [ "$PROC_COUNT" -ge "$RAW_COUNT" ] && [ "$SEM_COUNT" -ge "$PROC_COUNT" ] && [ -f "$SERV_FILE" ]; then
  echo "➡️ حالة خط الإنتاج: OK (المراحل الأساسية تبدو مكتملة)."
else
  echo "⚠️ حالة خط الإنتاج: WARNING (تحقق من توازن RAW/PROCESSED/SEMANTIC/SERVING)."
fi

# -----------------------------
section "4) فحص طبقة الذاكرة والجودة (ai/memory)"

MEM_DIR="ai/memory"
if [ -d "$MEM_DIR" ]; then
  status_line "مجلد الذاكرة $(short_path "$MEM_DIR")" "OK"
else
  status_line "مجلد الذاكرة $(short_path "$MEM_DIR")" "MISSING"
fi

MSG_FILE="$MEM_DIR/messages.jsonl"
if [ -f "$MSG_FILE" ]; then
  MSG_COUNT=$(wc -l < "$MSG_FILE" 2>/dev/null | tr -d ' ')
  echo "🧠 messages.jsonl : موجود – عدد الدورات المسجّلة ≈ $MSG_COUNT"
else
  echo "🧠 messages.jsonl : غير موجود"
fi

for f in "insights.json" "insights.txt" "quality.json" "quality_status.json" "quality_report.txt" "smart_actions.json" "smart_actions.txt"; do
  if [ -f "$MEM_DIR/$f" ]; then
    SIZE=$(stat -c%s "$MEM_DIR/$f" 2>/dev/null || echo 0)
    status_line "ملف $(short_path "$MEM_DIR/$f") (حجم=$SIZE بايت)" "OK"
  else
    status_line "ملف $(short_path "$MEM_DIR/$f")" "MISSING"
  fi
done

# -----------------------------
section "5) فحص الدروس (lessons) من الملفات ومن قاعدة المعرفة"

# ملفات lessons على القرص
shopt -s nullglob
LESSON_FILES=(ai/memory/lessons/*.json)
LESSON_FILE_COUNT=${#LESSON_FILES[@]}
shopt -u nullglob

echo "📚 ملفات الدروس على القرص: $LESSON_FILE_COUNT ملف(ات) في ai/memory/lessons/"
if [ "$LESSON_FILE_COUNT" -gt 0 ]; then
  echo "📋 أمثلة (أول 3):"
  idx=0
  for lf in "${LESSON_FILES[@]}"; do
    echo "  - $(short_path "$lf")"
    idx=$((idx+1))
    [ "$idx" -ge 3 ] && break
  done
fi

DB="data/knowledge/knowledge.db"
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$DB" ]; then
  echo
  echo "🔎 إحصائيات knowledge_items حسب النوع (من knowledge.db):"
  sqlite3 "$DB" "SELECT item_type, COUNT(*) FROM knowledge_items GROUP BY item_type;" 2>/dev/null || echo "⚠️ خطأ في استعلام sqlite."

  echo
  echo "🔎 عينة من عناصر lesson (حتى 5):"
  sqlite3 "$DB" "SELECT item_key, title, SUBSTR(meta_json,1,120) FROM knowledge_items WHERE item_type='lesson' LIMIT 5;" 2>/dev/null \
    | awk -F'|' '{printf "  - key=%s | title=%s | meta_prefix=%s\n",$1,$2,$3}' \
    || echo "⚠️ لا توجد دروس أو خطأ استعلام."

else
  echo
  echo "⚠️ sqlite3 غير متوفر أو قاعدة المعرفة غير موجودة، لن يتم فحص الدروس من DB."
fi

# -----------------------------
section "6) فحص مراحل المناهج (Curriculum Phases)"

HAS_CURRENT=0
if command -v sqlite3 >/dev/null 2>&1 && [ -f "$DB" ]; then
  echo "📋 جميع عناصر curriculum_phase (حتى 10):"
  sqlite3 "$DB" "SELECT item_key, title, SUBSTR(meta_json,1,160) FROM knowledge_items WHERE item_type='curriculum_phase' LIMIT 10;" 2>/dev/null \
    | awk -F'|' '{printf "  - key=%s | title=%s | meta_prefix=%s\n",$1,$2,$3}' \
    || echo "⚠️ لا توجد عناصر curriculum_phase أو خطأ استعلام."

  # محاولة اكتشاف Phase current/active من meta_json
  CURRENT_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM knowledge_items WHERE item_type='curriculum_phase' AND (meta_json LIKE '%\"current\": true%' OR meta_json LIKE '%\"active\": true%');" 2>/dev/null || echo "0")
  if [ "$CURRENT_COUNT" != "0" ]; then
    HAS_CURRENT=1
    echo
    echo "✅ تم العثور على مرحلة واحدة أو أكثر معلّمة كـ current/active في meta_json."
  else
    echo
    echo "⚠️ لا توجد أي curriculum_phase معلّمة كـ current/active في meta_json."
  fi
else
  echo "⚠️ تخطّي فحص curriculum_phase (لا sqlite3 أو لا DB)."
fi

# -----------------------------
section "7) فحص تقارير المدير والمالك والسياق (Manager / Owner / AI Context)"

LATEST_MANAGER_TXT=$(ls -1 reports/management/*_manager_daily_overview.txt 2>/dev/null | sort | tail -n 1 || echo "")
if [ -n "$LATEST_MANAGER_TXT" ]; then
  echo "📄 أحدث Manager Overview (TXT): $(short_path "$LATEST_MANAGER_TXT")"
  echo "----- أول 40 سطر من التقرير -----"
  head -n 40 "$LATEST_MANAGER_TXT" || true
else
  echo "⚠️ لا توجد تقارير Manager Overview."
fi

LATEST_OWNER=$(ls -1 reports/ai/OWNER_*_owner_report.md 2>/dev/null | sort | tail -n 1 || echo "")
if [ -n "$LATEST_OWNER" ]; then
  echo
  echo "📄 أحدث Owner Report: $(short_path "$LATEST_OWNER")"
else
  echo
  echo "⚠️ لا توجد Owner Reports."
fi

LATEST_SNAPSHOT=$(ls -1 reports/ai/*_ai_context_snapshot.md 2>/dev/null | sort | tail -n 1 || echo "")
if [ -n "$LATEST_SNAPSHOT" ]; then
  echo "📄 أحدث AI Context Snapshot: $(short_path "$LATEST_SNAPSHOT")"
else
  echo "⚠️ لا توجد AI Context Snapshots."
fi

# -----------------------------
section "8) فحص خطة تطبيق الدروس وملفات diff (config_changes)"

PLAN_FILE=$(ls -1 reports/management/lessons_apply_plan.md 2>/dev/null | sort | tail -n 1 || echo "")
AGENTS_DIFF=$(ls -1 config_changes/agents.diff 2>/dev/null | sort | tail -n 1 || echo "")
FACTORY_DIFF=$(ls -1 config_changes/factory.diff 2>/dev/null | sort | tail -n 1 || echo "")
APPLY_JSON_COUNT=$(ls -1 reports/config_changes/apply_lessons_*.json 2>/dev/null | wc -l | tr -d ' ')

if [ -n "$PLAN_FILE" ]; then
  status_line "خطة تطبيق الدروس $(short_path "$PLAN_FILE")" "OK"
else
  status_line "خطة تطبيق الدروس reports/management/lessons_apply_plan.md" "MISSING"
fi

if [ -n "$AGENTS_DIFF" ]; then
  status_line "ملف diff للـ agents $(short_path "$AGENTS_DIFF")" "OK"
else
  status_line "config_changes/agents.diff" "MISSING"
fi

if [ -n "$FACTORY_DIFF" ]; then
  status_line "ملف diff للـ factory $(short_path "$FACTORY_DIFF")" "OK"
else
  status_line "config_changes/factory.diff" "MISSING"
fi

echo "📊 عدد ملفات apply_lessons_*.json في reports/config_changes: $APPLY_JSON_COUNT"

# -----------------------------
section "9) فحص سكربتات العقل والتعلّم (hf_run_* المتعلقة بالBrain)"

RUN_SCRIPTS=(
  "hf_run_learning_cycle.sh"
  "hf_run_daily_ops.sh"
  "hf_run_export_lessons.sh"
  "hf_run_apply_lessons.sh"
  "hf_run_knowledge_spider.sh"
  "hf_run_offline_learner.sh"
  "hf_run_quality_worker.sh"
  "hf_run_system_architect.sh"
  "hf_run_smart_worker.sh"
  "hf_run_technical_coach.sh"
  "hf_run_manager_dashboard.sh"
)
for s in "${RUN_SCRIPTS[@]}"; do
  if [ -f "$s" ]; then
    if [ -x "$s" ]; then
      status_line "السكربت $s" "OK(x)"
    else
      status_line "السكربت $s موجود لكن غير قابل للتنفيذ" "WARN"
    fi
  else
    status_line "السكربت $s" "MISSING"
  fi
done

# -----------------------------
section "10) لمحة عن أتمتة systemd/cron (قراءة فقط)"

if command -v systemctl >/dev/null 2>&1; then
  echo "🔎 systemd units المرتبطة بـ hyper-factory (إن وجدت):"
  systemctl list-units | grep -i 'hyper-factory' || echo "  (لا وحدات hyper-factory ظاهرة أو لا توجد نتائج)"

  echo
  echo "🔎 systemd timers (بحث عن hyper / factory):"
  systemctl list-timers | grep -Ei 'hyper|factory' || echo "  (لا مؤقتات مرتبطة ظاهرة أو لا توجد نتائج)"
else
  echo "⚠️ systemctl غير متوفر في هذه البيئة، لن يتم فحص الوحدات/التايمرز."
fi

# -----------------------------
section "11) ملخص إداري نهائي"

echo "📌 ملخص:"
echo "  - RAW files       : $RAW_COUNT"
echo "  - PROCESSED meta  : $PROC_COUNT"
echo "  - SEMANTIC docs   : $SEM_COUNT"
echo "  - lessons files   : $LESSON_FILE_COUNT"
if [ -f "$DB" ] && command -v sqlite3 >/dev/null 2>&1; then
  LESSON_DB_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM knowledge_items WHERE item_type='lesson';" 2>/dev/null || echo "0")
  PHASE_DB_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM knowledge_items WHERE item_type='curriculum_phase';" 2>/dev/null || echo "0")
  echo "  - lessons in DB       : $LESSON_DB_COUNT"
  echo "  - curriculum phases   : $PHASE_DB_COUNT"
else
  echo "  - lessons in DB       : N/A (لا sqlite3 أو لا DB)"
  echo "  - curriculum phases   : N/A"
fi

if [ "$HAS_CURRENT" -eq 1 ]; then
  echo "  - current/active phase: FOUND"
else
  echo "  - current/active phase: NOT SET (⚠️ ينصح بتعيين Phase نشطة)"
fi

echo
echo "✅ الفحص انتهى. لا تعديلات تمت على أي ملف – التقرير تشخيصي فقط."
