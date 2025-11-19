#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

print_section() {
  echo -e ""
  echo -e "${BLUE}==================================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}==================================================${NC}"
}

print_status() {
  local name="$1"
  local status="$2"
  local note="${3:-}"
  local color="$NC"

  case "$status" in
    OK) color="$GREEN" ;;
    PARTIAL) color="$YELLOW" ;;
    MISSING) color="$RED" ;;
    *) color="$NC" ;;
  esac

  printf " - %-35s : %b%-8s%b" "$name" "$color" "$status" "$NC"
  if [[ -n "$note" ]]; then
    echo "  |  $note"
  else
    echo
  fi
}

# --------------------------------------------------
# 1) البنية التحتية المتقدمة
# --------------------------------------------------
check_infra() {
  print_section "1) Infrastructure – البنية التحتية المتقدمة"

  # data_lakehouse
  local dl_dir="$BASE_DIR/data_lakehouse"
  if [[ -d "$dl_dir" ]]; then
    local stages_found=0
    local stages=("raw" "cleansed" "semantic" "serving")

    for s in "${stages[@]}"; do
      if [[ -d "$dl_dir/$s" ]] || [[ -d "$dl_dir/${s^}" ]] || [[ -d "$dl_dir/${s^^}" ]]; then
        ((stages_found++))
      fi
    done

    if (( stages_found >= 3 )); then
      print_status "data_lakehouse" "OK" "المجلد موجود ومعظم مراحل (Raw/Cleansed/Semantic/Serving) موجودة."
    elif (( stages_found > 0 )); then
      print_status "data_lakehouse" "PARTIAL" "المجلد موجود وبعض المراحل فقط (${stages_found}/4) – يحتاج تنظيم."
    else
      print_status "data_lakehouse" "PARTIAL" "المجلد موجود بدون بنية مراحل واضحة – اليوم يعمل فعليًا عبر data/ + ai/memory."
    fi
  else
    print_status "data_lakehouse" "MISSING" "لا يوجد مجلد data_lakehouse في المشروع."
  fi

  # factories
  local factories_dir="$BASE_DIR/factories"
  if [[ -d "$factories_dir" ]]; then
    local fac_found=0
    local facs=("models" "knowledge" "quality" "model_factory" "knowledge_factory" "quality_factory")
    for f in "${facs[@]}"; do
      if [[ -d "$factories_dir/$f" ]]; then
        ((fac_found++))
      fi
    done

    if (( fac_found >= 3 )); then
      print_status "factories" "OK" "بنية factories موجودة بعدة وحدات (${fac_found})."
    elif (( fac_found > 0 )); then
      print_status "factories" "PARTIAL" "مجلد factories موجود لكن وحدات محدودة (${fac_found}) – المنطق متوزع اليوم بين السكربتات."
    else
      print_status "factories" "PARTIAL" "مجلد factories موجود لكن بدون مصانع فرعية واضحة."
    fi
  else
    print_status "factories" "MISSING" "لا يوجد مجلد factories – “مصنع” النماذج/المعرفة/الجودة يعمل حاليًا كعمليات متناثرة."
  fi

  # stack
  local stack_dir="$BASE_DIR/stack"
  if [[ -d "$stack_dir" ]]; then
    print_status "stack" "OK" "مجلد stack موجود (GPU/Model Serving/VectorDB حسب محتواه)."
  else
    print_status "stack" "MISSING" "لا يوجد stack داخل hyper-factory – الstack الحقيقي اليوم في ffactory/ollama/postgres خارج هذا المشروع."
  fi
}

# --------------------------------------------------
# 2) العوامل المتقدمة (Agents)
# --------------------------------------------------
check_agents() {
  print_section "2) Advanced Agents – العوامل المتقدمة"

  local agents_conf="$BASE_DIR/config/agents.yaml"
  if [[ ! -f "$agents_conf" ]]; then
    echo -e "${RED}⚠ config/agents.yaml غير موجود – لا يمكن فحص العوامل.${NC}"
    return
  fi

  local agents=("debug_expert" "system_architect" "technical_coach" "knowledge_spider")

  for a in "${agents[@]}"; do
    local score=0
    local details=()

    # 1) وجود في ملف التكوين
    if grep -q "$a" "$agents_conf"; then
      ((score++))
      details+=("config")
    fi

    # 2) سكربت تشغيل
    local run_script="$BASE_DIR/hf_run_${a}.sh"
    if [[ -x "$run_script" ]]; then
      ((score++))
      details+=("run_script")
    elif [[ -f "$run_script" ]]; then
      ((score++))
      details+=("run_script(non-exec)")
    fi

    # 3) أداة Python
    local py_tool="$BASE_DIR/tools/hf_${a}.py"
    if [[ -f "$py_tool" ]]; then
      ((score++))
      details+=("python_tool")
    fi

    # 4) مجلد agent مستقل
    local agent_dir="$BASE_DIR/agents/$a"
    if [[ -d "$agent_dir" ]]; then
      ((score++))
      details+=("agent_dir")
    fi

    local status="MISSING"
    case "$score" in
      4) status="OK" ;;
      1|2|3) status="PARTIAL" ;;
      0) status="MISSING" ;;
    esac

    local note=""
    if (( score > 0 )); then
      note="components: ${score}/4 [$(IFS=,; echo "${details[*]}")]"
    else
      note="لا يوجد تكوين أو سكربت أو مجلد واضح لهذا العامل."
    fi

    print_status "agent: $a" "$status" "$note"
  done
}

# --------------------------------------------------
# 3) الأنظمة المتقدمة (Patterns / Quality / Temporal / Integration)
# --------------------------------------------------
check_advanced_systems() {
  print_section "3) Advanced Systems – الأنظمة المتقدمة"

  # Patterns
  local patterns_status="MISSING"
  local patterns_note=""
  local patterns_script="$BASE_DIR/tools/hf_offline_learner.py"
  local patterns_dir="$BASE_DIR/ai/memory/offline/patterns"

  if [[ -f "$patterns_script" ]] || [[ -d "$patterns_dir" ]]; then
    local count_pat=0
    if [[ -d "$patterns_dir" ]]; then
      shopt -s nullglob
      local files=("$patterns_dir"/*patterns*.json)
      count_pat="${#files[@]}"
      shopt -u nullglob
    fi

    if [[ -f "$patterns_script" && -d "$patterns_dir" && "$count_pat" -gt 0 ]]; then
      patterns_status="OK"
      patterns_note="hf_offline_learner موجود وملفات patterns (${count_pat}) – النظام فعّال."
    else
      patterns_status="PARTIAL"
      patterns_note="offline_learner موجود لكن ملفات patterns محدودة/غير مكتملة (count=${count_pat})."
    fi
  else
    patterns_status="MISSING"
    patterns_note="لا يوجد hf_offline_learner ولا مجلد patterns تحت ai/memory/offline."
  fi
  print_status "Patterns System" "$patterns_status" "$patterns_note"

  # Quality
  local quality_script="$BASE_DIR/hf_run_quality_worker.sh"
  local quality_status_file="$BASE_DIR/ai/memory/quality_status.json"
  local quality_status="MISSING"
  local quality_note=""

  if [[ -f "$quality_script" ]] || [[ -f "$quality_status_file" ]]; then
    if [[ -f "$quality_script" && -f "$quality_status_file" ]]; then
      quality_status="OK"
      quality_note="hf_run_quality_worker موجود وquality_status.json موجود – نظام الجودة فعّال."
    else
      quality_status="PARTIAL"
      quality_note="جزء من نظام الجودة موجود (script/status) ولكن ليس بالكامل."
    fi
  else
    quality_status="MISSING"
    quality_note="لا يوجد لا سكربت quality_worker ولا quality_status.json في ai/memory."
  fi
  print_status "Quality System" "$quality_status" "$quality_note"

  # Temporal Memory
  local temporal_dir="$BASE_DIR/ai/memory/temporal"
  local temporal_status="MISSING"
  local temporal_note=""

  if [[ -d "$temporal_dir" ]]; then
    shopt -s nullglob
    local tfiles=("$temporal_dir"/*.json)
    local tcount="${#tfiles[@]}"
    shopt -u nullglob
    if (( tcount > 0 )); then
      temporal_status="PARTIAL"
      temporal_note="مجلد temporal موجود مع ${tcount} ملف – بداية نظام ذاكرة زمنية (seed/experimental)."
    else
      temporal_status="PARTIAL"
      temporal_note="مجلد temporal موجود بدون ملفات – يحتاج تشغيل محركات الزمن."
    fi
  else
    temporal_status="MISSING"
    temporal_note="لا يوجد ai/memory/temporal حتى الآن."
  fi
  print_status "Temporal Memory" "$temporal_status" "$temporal_note"

  # Integration System
  local integration_status="MISSING"
  local integration_note=""
  local integration_hits=0

  # نحاول نلقط أي تكامل من ملفات config أو مجلدات integrations/connectors
  if grep -qiE "integration|external|connector|webhook" "$BASE_DIR"/config/*.yaml 2>/dev/null; then
    ((integration_hits++))
  fi
  if [[ -d "$BASE_DIR/integrations" ]] || [[ -d "$BASE_DIR/connectors" ]]; then
    ((integration_hits++))
  fi

  if (( integration_hits >= 2 )); then
    integration_status="OK"
    integration_note="تعريفات ومجلدات تكامل موجودة داخل المشروع."
  elif (( integration_hits == 1 )); then
    integration_status="PARTIAL"
    integration_note="مؤشرات تكامل موجودة في config أو مجلدات، لكنها ليست نظامًا مستقلاً بعد."
  else
    integration_status="MISSING"
    integration_note="لا يوجد نظام تكامل واضح داخل hyper-factory – التكامل حالياً عبر smartfriend/ffactory خارج هذا المشروع."
  fi

  print_status "Integration System" "$integration_status" "$integration_note"
}

main() {
  echo -e "${BLUE}Hyper Factory – Advanced Infra & Agents Check${NC}"
  echo "ROOT: $BASE_DIR"
  echo "TIME: $(date -Iseconds)"
  echo

  check_infra
  check_agents
  check_advanced_systems

  echo -e ""
  echo -e "${BLUE}==================================================${NC}"
  echo -e "${BLUE}Summary: الفحص اكتمل (قراءة فقط – لا تعديل).${NC}"
  echo -e "${BLUE}==================================================${NC}"
}

main "\$@"
