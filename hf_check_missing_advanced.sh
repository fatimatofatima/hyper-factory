#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
REPORT_DIR="$BASE_DIR/reports/diagnostics"
REPORT_FILE="$REPORT_DIR/hf_missing_advanced_${TS}.txt"

mkdir -p "$REPORT_DIR"

green()  { printf "\033[0;32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[0;33m%s\033[0m\n" "$*"; }
red()    { printf "\033[0;31m%s\033[0m\n" "$*"; }

status_line() {
  local label="$1" state="$2" details="${3:-}"
  case "$state" in
    OK)  printf "✅ %-40s : OK %s\n" "$label" "$details" ;;
    PARTIAL) printf "⚠️  %-40s : PARTIAL %s\n" "$label" "$details" ;;
    MISSING) printf "❌ %-40s : MISSING %s\n" "$label" "$details" ;;
    *) printf "❓ %-40s : %s %s\n" "$label" "$state" "$details" ;;
  esac
}

check_dir() {
  local path="$1"
  [[ -d "$path" ]] && echo "OK" || echo "MISSING"
}

check_file() {
  local path="$1"
  [[ -f "$path" ]] && echo "OK" || echo "MISSING"
}

echo "🔍 Hyper Factory – Advanced Checklist Audit" | tee "$REPORT_FILE"
echo "⏰ $(date)" | tee -a "$REPORT_FILE"
echo "📍 $BASE_DIR" | tee -a "$REPORT_FILE"
echo "===============================================" | tee -a "$REPORT_FILE"
echo >> "$REPORT_FILE"

##################################################
# 1) البنية التحتية المتقدمة (Advanced Infra)
##################################################
echo "🏗️  البنية التحتية المتقدمة" | tee -a "$REPORT_FILE"
echo "-----------------------------------------------" | tee -a "$REPORT_FILE"

# 1.1 data_lakehouse/ (Raw → Cleansed → Semantic → Serving)
DL_ROOT="data_lakehouse"
DL_RAW="$DL_ROOT/raw"
DL_CLEANSED="$DL_ROOT/cleansed"
DL_SEMANTIC="$DL_ROOT/semantic"
DL_SERVING="$DL_ROOT/serving"

if [[ -d "$DL_ROOT" ]]; then
  missing_sub=0
  [[ -d "$DL_RAW"      ]] || missing_sub=$((missing_sub+1))
  [[ -d "$DL_CLEANSED" ]] || missing_sub=$((missing_sub+1))
  [[ -d "$DL_SEMANTIC" ]] || missing_sub=$((missing_sub+1))
  [[ -d "$DL_SERVING"  ]] || missing_sub=$((missing_sub+1))

  if (( missing_sub == 0 )); then
    state="OK"
    detail="(raw/cleansed/semantic/serving مكتملة)"
  else
    state="PARTIAL"
    detail="(مجلد رئيسي موجود، لكن $missing_sub من subdirs مفقودة)"
  fi
else
  state="MISSING"
  detail="(data_lakehouse/ غير موجودة)"
fi

status_line "data_lakehouse" "$state" "$detail" | tee -a "$REPORT_FILE"

# 1.2 factories/ (مصنع النماذج - مصنع المعرفة - مصنع الجودة)
FACT_ROOT="factories"
if [[ -d "$FACT_ROOT" ]]; then
  # نفترض 3 مصانع: model_factory / knowledge_factory / quality_factory (اختيارية الآن)
  sub_missing=0
  [[ -d "$FACT_ROOT/model_factory"      ]] || sub_missing=$((sub_missing+1))
  [[ -d "$FACT_ROOT/knowledge_factory"  ]] || sub_missing=$((sub_missing+1))
  [[ -d "$FACT_ROOT/quality_factory"    ]] || sub_missing=$((sub_missing+1))

  if (( sub_missing == 0 )); then
    state="OK"
    detail="(model/knowledge/quality factories موجودة)"
  elif (( sub_missing == 3 )); then
    state="PARTIAL"
    detail="(factories/ موجودة لكن المصانع الفرعية غير معرفة بعد – تصميم placeholder)"
  else
    state="PARTIAL"
    detail="(factories/ موجودة وبعض المصانع الفرعية مفقودة: $sub_missing)"
  fi
else
  state="MISSING"
  detail="(factories/ غير موجودة)"
fi
status_line "factories" "$state" "$detail" | tee -a "$REPORT_FILE"

# 1.3 stack/ (GPU cluster - Model serving - Vector DB)
STACK_ROOT="stack"
if [[ -d "$STACK_ROOT" ]]; then
  st_missing=0
  [[ -d "$STACK_ROOT/gpu_cluster"  ]] || st_missing=$((st_missing+1))
  [[ -d "$STACK_ROOT/model_serving" ]] || st_missing=$((st_missing+1))
  [[ -d "$STACK_ROOT/vector_db"    ]] || st_missing=$((st_missing+1))

  if (( st_missing == 0 )); then
    state="OK"
    detail="(gpu_cluster/model_serving/vector_db جاهزة أو placeholders)"
  elif (( st_missing == 3 )); then
    state="PARTIAL"
    detail="(stack/ موجودة بدون subdirs مخصصة – تصميم placeholder)"
  else
    state="PARTIAL"
    detail="(stack/ موجودة وبعض المكونات الفرعية ناقصة: $st_missing)"
  fi
else
  state="MISSING"
  detail="(stack/ غير موجودة)"
fi
status_line "stack" "$state" "$detail" | tee -a "$REPORT_FILE"

echo >> "$REPORT_FILE"

##################################################
# 2) العوامل المتقدمة (Advanced Agents)
##################################################
echo "🤖 العوامل المتقدمة" | tee -a "$REPORT_FILE"
echo "-----------------------------------------------" | tee -a "$REPORT_FILE"

check_agent_dir() {
  local name="$1"
  local path="agents/$name"
  local readme="$path/README.md"
  local init_py="$path/__init__.py"

  if [[ ! -d "$path" ]]; then
    status_line "agent: $name" "MISSING" "(agents/$name غير موجودة)" | tee -a "$REPORT_FILE"
    return
  fi

  local missing=0
  [[ -f "$readme"  ]] || missing=$((missing+1))
  [[ -f "$init_py" ]] || missing=$((missing+1))

  if (( missing == 0 )); then
    status_line "agent: $name" "OK" "(هيكل + README + __init__.py)" | tee -a "$REPORT_FILE"
  else
    status_line "agent: $name" "PARTIAL" "(مجلد موجود لكن ملفات تعريف ناقصة: $missing)" | tee -a "$REPORT_FILE"
  fi
}

for AG in debug_expert system_architect technical_coach knowledge_spider; do
  check_agent_dir "$AG"
done

echo >> "$REPORT_FILE"

##################################################
# 3) الأنظمة المتقدمة (Patterns / Quality / Temporal / Integration)
##################################################
echo "⚙️  الأنظمة المتقدمة" | tee -a "$REPORT_FILE"
echo "-----------------------------------------------" | tee -a "$REPORT_FILE"

# 3.1 نظام الأنماط (Patterns) - التعلم من الأخطاء
PAT_ROOT="ai/patterns"
PAT_INDEX="$PAT_ROOT/patterns_index.json"
if [[ -d "$PAT_ROOT" ]]; then
  if [[ -f "$PAT_INDEX" ]]; then
    state="OK"
    detail="(ai/patterns + patterns_index.json موجودة)"
  else
    state="PARTIAL"
    detail="(مجلد ai/patterns موجود لكن patterns_index.json مفقود أو placeholder)"
  fi
else
  state="MISSING"
  detail="(ai/patterns غير موجودة)"
fi
status_line "نظام الأنماط (patterns)" "$state" "$detail" | tee -a "$REPORT_FILE"

# 3.2 نظام الجودة (Quality) - التقييم التلقائي
Q_ROOT="ai/quality"
Q_STATUS="ai/memory/quality_status.json"
Q_SCRIPT="tools/hf_quality_worker.py"
Q_RUN="hf_run_quality_worker.sh"

if [[ -d "$Q_ROOT" ]]; then
  missing=0
  [[ -f "$Q_STATUS" ]] || missing=$((missing+1))
  [[ -f "$Q_SCRIPT" ]] || missing=$((missing+1))
  [[ -f "$Q_RUN"    ]] || missing=$((missing+1))

  if (( missing == 0 )); then
    state="OK"
    detail="(ai/quality + worker script + memory status مكتملة)"
  else
    state="PARTIAL"
    detail="(نظام الجودة موجود لكن $missing مكونات ناقصة)"
  fi
else
  state="MISSING"
  detail="(ai/quality غير موجودة)"
fi
status_line "نظام الجودة (quality)" "$state" "$detail" | tee -a "$REPORT_FILE"

# 3.3 نظام الذاكرة الزمنية - تطور المستخدمين
T_ROOT="ai/memory/temporal"
T_SEED="$T_ROOT/seed_state.json"

if [[ -d "$T_ROOT" ]]; then
  if [[ -f "$T_SEED" ]]; then
    state="OK"
    detail="(ذاكرة زمنية مبدئية seed_state.json موجودة)"
  else
    state="PARTIAL"
    detail="(مجلد temporal موجود بدون seed_state.json)"
  fi
else
  state="MISSING"
  detail="(ai/memory/temporal غير موجودة)"
fi
status_line "نظام الذاكرة الزمنية" "$state" "$detail" | tee -a "$REPORT_FILE"

# 3.4 نظام التكامل - ربط مع أنظمة خارجية
INT_ROOT="integrations"
INT_MANIFEST="$INT_ROOT/integrations_manifest.yaml"

if [[ -d "$INT_ROOT" ]]; then
  if [[ -f "$INT_MANIFEST" ]]; then
    state="OK"
    detail="(integrations/ + integrations_manifest.yaml موجودة)"
  else
    state="PARTIAL"
    detail="(integrations/ موجودة بدون manifest واضح)"
  fi
else
  state="MISSING"
  detail="(integrations/ غير موجودة)"
fi
status_line "نظام التكامل (integrations)" "$state" "$detail" | tee -a "$REPORT_FILE"

echo >> "$REPORT_FILE"

##################################################
# ملخص نهائي
##################################################
echo "📊 الملخص النهائي" | tee -a "$REPORT_FILE"
echo "-----------------------------------------------" | tee -a "$REPORT_FILE"

# حساب سريع عبر التقرير نفسه
TOTAL_OK=$(grep -c " : OK" "$REPORT_FILE" || true)
TOTAL_PARTIAL=$(grep -c " : PARTIAL" "$REPORT_FILE" || true)
TOTAL_MISSING=$(grep -c " : MISSING" "$REPORT_FILE" || true)

echo "✅ عناصر مكتملة  : $TOTAL_OK"     | tee -a "$REPORT_FILE"
echo "⚠️  عناصر جزئية  : $TOTAL_PARTIAL" | tee -a "$REPORT_FILE"
echo "❌ عناصر مفقودة  : $TOTAL_MISSING" | tee -a "$REPORT_FILE"

echo
green "✅ تم إنشاء تقرير مفصل في:"
echo "   $REPORT_FILE"
