#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BASE_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

present=0
partial=0
missing=0

header() {
  echo -e ""
  echo -e "${BLUE}==================================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}==================================================${NC}"
}

status_full() {
  echo -e "   ${GREEN}✅ مكتمل${NC} - $1"
  ((present++))
}

status_partial() {
  echo -e "   ${YELLOW}🟡 جزئي${NC} - $1"
  ((partial++))
}

status_missing() {
  echo -e "   ${RED}❌ مفقود${NC} - $1"
  ((missing++))
}

check_data_lakehouse() {
  header "1) البنية التحتية المتقدمة (data_lakehouse / factories / stack)"

  # data_lakehouse
  local root="data_lakehouse"
  local ok_root=0
  local layers=0

  [ -d "$root" ] && ok_root=1 || true

  for d in raw cleansed semantic serving; do
    [ -d "$root/$d" ] && ((layers++)) || true
  done

  if (( ok_root == 1 && layers == 4 )); then
    status_full "data_lakehouse (Raw/Cleansed/Semantic/Serving)"
  elif (( ok_root == 1 || layers > 0 )); then
    status_partial "data_lakehouse (موجودة لكن بعض الطبقات ناقص)"
  else
    status_missing "data_lakehouse (غير موجودة)"
  fi

  # factories
  local froot="factories"
  local f_sub=0
  for d in model_factory knowledge_factory quality_factory; do
    [ -d "$froot/$d" ] && ((f_sub++)) || true
  done

  if [ -d "$froot" ] && (( f_sub >= 3 )); then
    status_full "factories (مصنع النماذج/المعرفة/الجودة مكتمل)"
  elif [ -d "$froot" ] || (( f_sub > 0 )); then
    status_partial "factories (مجلد موجود لكن بدون مصانع فرعية كاملة)"
  else
    status_missing "factories (غير موجودة كبنية واضحة)"
  fi

  # stack
  local sroot="stack"
  local s_sub=0
  for d in gpu_cluster model_serving vector_db; do
    [ -d "$sroot/$d" ] && ((s_sub++)) || true
  done

  if [ -d "$sroot" ] && (( s_sub >= 3 )); then
    status_full "stack (GPU / Model serving / Vector DB)"
  elif [ -d "$sroot" ] || (( s_sub > 0 )); then
    status_partial "stack (مجلد موجود بدون مكوّنات كاملة)"
  else
    status_missing "stack (غير موجودة كبنية واضحة)"
  fi
}

check_agent() {
  local id="$1"
  local nice="$2"
  local run_script="$3"
  local tool="$4"
  local dir="agents/$id"

  echo -e ""
  echo -e "${BLUE}🔹 عامل: $nice ($id)${NC}"

  local have_script=0
  local have_tool=0
  local have_dir=0

  [ -x "$run_script" ] && have_script=1 || true
  [ -f "$tool" ] && have_tool=1 || true
  [ -d "$dir" ] && have_dir=1 || true

  if (( have_script == 1 && have_tool == 1 && have_dir == 1 )); then
    status_full "$nice - سكربت + أداة + مجلد عامل"
  elif (( have_script == 1 || have_tool == 1 )); then
    status_partial "$nice - سكربت/أداة موجودة لكن مجلد agents/$id مفقود"
  else
    status_missing "$nice - لا سكربت ولا أداة ولا مجلد عامل"
  fi
}

check_advanced_agents() {
  header "2) العوامل المتقدمة (Advanced Agents)"

  check_agent "debug_expert" "عامل تصحيح الأخطاء" \
    "hf_run_debug_expert.sh" "tools/hf_debug_expert.py"

  check_agent "system_architect" "عامل التصميم المعماري" \
    "hf_run_system_architect.sh" "tools/hf_system_architect.py"

  check_agent "technical_coach" "عامل التدريب التقني" \
    "hf_run_technical_coach.sh" "tools/hf_technical_coach.py"

  check_agent "knowledge_spider" "عامل جمع المعرفة" \
    "hf_run_knowledge_spider.sh" "tools/hf_knowledge_spider.py"
}

check_advanced_systems() {
  header "3) الأنظمة المتقدمة (Patterns / Quality / Temporal / Integration)"

  # Patterns system
  if [ -d "systems/patterns" ]; then
    status_full "نظام الأنماط (systems/patterns/)"
  elif ls ai/memory/offline/*patterns* >/dev/null 2>&1; then
    status_partial "نظام الأنماط - موجود كملفات أنماط في ai/memory/offline/ لكن بدون نظام رسمي"
  else
    status_missing "نظام الأنماط - غير موجود كنظام واضح"
  fi

  # Quality system
  if [ -d "systems/quality" ]; then
    status_full "نظام الجودة (systems/quality/)"
  elif [ -f "tools/hf_quality_worker.py" ]; then
    status_partial "نظام الجودة - موجود عبر quality_worker لكن بدون نظام مستقل"
  else
    status_missing "نظام الجودة - غير موجود كنظام واضح"
  fi

  # Temporal memory system
  if [ -d "systems/temporal_memory" ]; then
    status_full "نظام الذاكرة الزمنية (systems/temporal_memory/)"
  elif [ -d "ai/memory/temporal" ]; then
    status_partial "نظام الذاكرة الزمنية - ai/memory/temporal موجود لكن بدون نظام متكامل"
  else
    status_missing "نظام الذاكرة الزمنية - غير موجود"
  fi

  # Integration system
  if [ -d "systems/integration" ]; then
    status_full "نظام التكامل (systems/integration/)"
  elif grep -q "smartfriend" config/factory.yaml 2>/dev/null || \
       grep -q "ffactory"   config/factory.yaml 2>/dev/null; then
    status_partial "نظام التكامل - تكامل منطقي مع SmartFriend/ffactory لكن بدون systems/integration/"
  else
    status_missing "نظام التكامل - غير موجود كبنية مستقلة"
  fi
}

summary() {
  header "4) الملخص النهائي"
  echo -e "   ✅ مكتمل:  $present مكوّن"
  echo -e "   🟡 جزئي:   $partial مكوّن"
  echo -e "   ❌ مفقود:  $missing مكوّن"
  echo ""
  echo -e "📌 الأولوية القادمة: معالجة العناصر ❌ ثم 🟡."
}

echo "🔍 Hyper Factory – فحص المفقودات الاستراتيجية"
echo "ROOT: $BASE_DIR"
echo "TIME: $(date +%Y-%m-%dT%H:%M:%S%z)"
echo ""

check_data_lakehouse
check_advanced_agents
check_advanced_systems
summary
