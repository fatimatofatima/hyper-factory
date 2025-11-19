#!/bin/bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT" 2>/dev/null || {
  echo "❌ لا يمكن الدخول إلى $ROOT"
  exit 1
}

mkdir -p reports/diagnostics
REPORT="reports/diagnostics/hf_gaps_check_$(date +%Y%m%d_%H%M%S).txt"

section() {
  echo
  echo "=============================="
  echo "▶ $1"
  echo "=============================="
  echo >> "$REPORT"
  echo "▶ $1" >> "$REPORT"
  echo "------------------------------" >> "$REPORT"
}

log() {
  echo "$1"
  echo "$1" >> "$REPORT"
}

check_dir() {
  local label="$1"
  local path="$2"
  if [ -d "$path" ]; then
    log "✅ DIR موجود: $label → $path"
    return 0
  else
    log "❌ DIR ناقص: $label → $path"
    return 1
  fi
}

check_file() {
  local label="$1"
  local path="$2"
  if [ -f "$path" ]; then
    log "✅ FILE موجود: $label → $path"
    return 0
  else
    log "❌ FILE ناقص: $label → $path"
    return 1
  fi
}

check_pattern_in_dir() {
  local label="$1"
  local base="$2"
  local pattern="$3"
  if [ -d "$base" ] && find "$base" -maxdepth 3 -iname "$pattern" -print -quit | grep -q .; then
    local found
    found=$(find "$base" -maxdepth 3 -iname "$pattern" -print -quit)
    log "✅ عنصر موجود ($label): $found"
    return 0
  else
    log "❌ عنصر ناقص ($label) بنمط: $pattern داخل $base"
    return 1
  fi
}

echo "📊 Hyper Factory – فحص النواقص المتقدمة"
echo "📍 المسار: $(pwd)"
echo "⏰ الوقت: $(date)"
echo
echo "📄 سيتم حفظ التقرير في: $REPORT"
echo "..."

echo "📌 بدء الفحص..." > "$REPORT"
echo "تاريخ الفحص: $(date)" >> "$REPORT"
echo "المسار: $(pwd)" >> "$REPORT"
echo >> "$REPORT"

########################################
# 1) طبقة البيانات و Lakehouse
########################################
section "1) طبقة البيانات و Lakehouse"

check_dir "data/inbox"     "data/inbox"
check_dir "data/raw"       "data/raw"
check_dir "data/processed" "data/processed"
check_dir "data/semantic"  "data/semantic"
check_dir "data/serving"   "data/serving"

if [ -d "data_lakehouse" ]; then
  log "✅ DIR data_lakehouse موجود"
  check_dir "Raw Zone"      "data_lakehouse/raw"
  check_dir "Cleansed Zone" "data_lakehouse/cleansed"
  check_dir "Semantic Zone" "data_lakehouse/semantic"
  check_dir "Serving Zone"  "data_lakehouse/serving"
  check_dir "Catalog/Schema" "data_lakehouse/catalog"
else
  log "⚠️ لا يوجد data_lakehouse/ → البنية تعمل كـ pipeline بسيط، ليست Lakehouse مكتملة."
fi

########################################
# 2) factories / stack
########################################
section "2) factories و stack"

check_dir "مصنع النماذج والمعرفة (factories)" "factories"
check_dir "Stack النماذج / GPU / Vector DB (stack)" "stack"

if ls config 1>/dev/null 2>&1; then
  if find config -maxdepth 1 -iname "*stack*" -o -iname "*model*" | grep -q . 2>/dev/null; then
    log "ℹ️ توجد ملفات config تتعلق بالـ stack / models في config/"
  else
    log "ℹ️ لا توجد ملفات واضحة للـ stack في config/ (فحص سريع بالاسم فقط)"
  fi
else
  log "ℹ️ مجلد config/ غير موجود أو غير مقروء"
fi

########################################
# 3) Agents / العمال المتقدمين
########################################
section "3) Agents / العمال المتقدمين"

check_dir "agents/" "agents"

EXPECTED_AGENTS=(
  "debug_expert"
  "system_architect"
  "technical_coach"
  "knowledge_spider"
  "patterns_engine"
  "quality_engine"
  "temporal_memory"
  "integration_hub"
)

if [ -d "agents" ]; then
  for ag in "${EXPECTED_AGENTS[@]}"; do
    if find agents -maxdepth 3 -iname "*${ag}*" -print -quit | grep -q . 2>/dev/null; then
      found=$(find agents -maxdepth 3 -iname "*${ag}*" -print -quit)
      log "✅ Agent موجود (${ag}): $found"
    else
      log "❌ Agent ناقص (${ag}) داخل agents/"
    fi
  done
else
  log "⚠️ لا يوجد مجلد agents/، كل العمال المتقدمين تعتبر ناقصة."
fi

########################################
# 4) Lifelong Learning System
########################################
section "4) Lifelong Learning System"

LEARNING_ROOT_CANDIDATES=(
  "LearningSystem"
  "learning_system"
  "lifelong_learning"
)

learning_root_found=""

for cand in "${LEARNING_ROOT_CANDIDATES[@]}"; do
  if [ -d "$cand" ]; then
    learning_root_found="$cand"
    log "✅ مجلد نظام التعلّم المستمر موجود: $cand"
    break
  fi
done

if [ -z "$learning_root_found" ]; then
  log "❌ لا يوجد مجلد واضح لـ Lifelong Learning System (LearningSystem/ أو ما شابه)"
else
  check_dir "Online-Loop"  "$learning_root_found/Online-Loop"
  check_dir "Offline-Loop" "$learning_root_found/Offline-Loop"
  check_dir "Curriculum"   "$learning_root_found/Curriculum"
  check_dir "Learning-Memory" "$learning_root_found/Learning-Memory"
fi

########################################
# 5) أنظمة الأنماط والجودة والذاكرة الزمنية
########################################
section "5) أنظمة الأنماط والجودة والذاكرة الزمنية"

check_pattern_in_dir "Patterns System (أنظمة الأنماط)" "." "*pattern*engine*.py"
check_pattern_in_dir "Patterns System (أنظمة الأنماط)" "tools" "*pattern*"

check_pattern_in_dir "Quality System (نظام الجودة)" "." "*quality*engine*.py"
check_pattern_in_dir "Quality System (نظام الجودة)" "tools" "*quality*"

check_pattern_in_dir "Temporal / Learning Memory" "." "*temporal*memory*.py"
check_pattern_in_dir "Learning Progress / User Memory" "." "*learning*progress*.py"

########################################
# 6) Integration Hub / Gateways
########################################
section "6) Integration Hub / Gateways"

check_dir "integrations/" "integrations"

if [ -d "integrations" ]; then
  check_pattern_in_dir "Integration with SmartFriend/ffactory" "integrations" "*smartfriend*"
  check_pattern_in_dir "Integration with Telegram/External Bots" "integrations" "*telegram*"
  check_pattern_in_dir "Integration with LLM providers" "integrations" "*openai*"
else
  log "⚠️ لا يوجد مجلد integrations/ كنقطة تكامل مركزية"
fi

########################################
# 7) ملخص
########################################
section "7) ملخص تنفيذي"

log "هذا الفحص يعتمد على أسماء ومسارات متوقعة."
log "أي مكوّن مُسمّى باسم مختلف قد يظهر كـ ناقص في هذا التقرير."
log "يمكن تعديل أنماط البحث داخل السكربت لتناسب التسمية النهائية في المشروع."
log
log "📄 التقرير الكامل في: $REPORT"

echo
echo "✅ تم إنهاء فحص النواقص المتقدمة."
echo "📄 التقرير: $REPORT"
