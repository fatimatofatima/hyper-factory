#!/usr/bin/env bash
# ensure_agents_block.sh
# يتأكد أن agents.yaml يحتوي على:
# - agents:
#   - ingestor_basic
#   - processor_basic
# ولو ناقص يضيفه بدون حذف أو استبدال الموجود.

set -euo pipefail

ROOT="/root/hyper-factory"
CONFIG_DIR="$ROOT/config"
FILE="$CONFIG_DIR/agents.yaml"

mkdir -p "$CONFIG_DIR"
mkdir -p "$ROOT/tools"

echo "📄 الهدف: $FILE"

# 1) لو الملف مش موجود: إنشاؤه بالكامل
if [[ ! -f "$FILE" ]]; then
  echo "ℹ️ الملف غير موجود، سيتم إنشاؤه من الصفر."
  cat > "$FILE" << 'YAML'
agents:
  ingestor_basic:
    enabled: true
    input:
      path: "data/raw"
    output:
      path: "data/processed"

  processor_basic:
    enabled: true
    input:
      path: "data/processed"
    output:
      path: "data/semantic"
YAML
  echo "✅ تم إنشاء agents.yaml مع البلوك المطلوب."
  exit 0
fi

# 2) الملف موجود: فحص وجود agents: في الجذر
if grep -qE '^[[:space:]]*agents:' "$FILE"; then
  HAS_AGENTS_ROOT=1
else
  HAS_AGENTS_ROOT=0
fi

# 3) فحص وجود البلوكات
grep -q 'ingestor_basic:' "$FILE" && HAS_INGESTOR=1 || HAS_INGESTOR=0
grep -q 'processor_basic:' "$FILE" && HAS_PROCESSOR=1 || HAS_PROCESSOR=0

if [[ "$HAS_AGENTS_ROOT" -eq 1 && "$HAS_INGESTOR" -eq 1 && "$HAS_PROCESSOR" -eq 1 ]]; then
  echo "✅ البلوك موجود بالكامل بالفعل، لا تعديل."
  exit 0
fi

# 4) لو مفيش agents: أصلاً → إضافة بلوك كامل جديد
if [[ "$HAS_AGENTS_ROOT" -eq 0 ]]; then
  echo "ℹ️ لا يوجد agents: في الجذر، سيتم إضافة بلوك كامل في آخر الملف."
  cat >> "$FILE" << 'YAML'

agents:
  ingestor_basic:
    enabled: true
    input:
      path: "data/raw"
    output:
      path: "data/processed"

  processor_basic:
    enabled: true
    input:
      path: "data/processed"
    output:
      path: "data/semantic"
YAML
  echo "✅ تم إضافة agents + ingestor_basic + processor_basic في نهاية الملف."
  exit 0
fi

# 5) هنا عندنا agents: موجودة، لكن واحد أو الاتنين ناقصين → نضيفهم تحتها
echo "ℹ️ يوجد agents: في الملف، سيتم حقن البلوكات الناقصة فقط في آخر الملف تحت نفس الجذر."

ADDED=0

if [[ "$HAS_INGESTOR" -eq 0 ]]; then
  cat >> "$FILE" << 'YAML'

  ingestor_basic:
    enabled: true
    input:
      path: "data/raw"
    output:
      path: "data/processed"
YAML
  echo "✅ تم إضافة ingestor_basic"
  ADDED=1
fi

if [[ "$HAS_PROCESSOR" -eq 0 ]]; then
  cat >> "$FILE" << 'YAML'

  processor_basic:
    enabled: true
    input:
      path: "data/processed"
    output:
      path: "data/semantic"
YAML
  echo "✅ تم إضافة processor_basic"
  ADDED=1
fi

if [[ "$ADDED" -eq 0 ]]; then
  echo "ℹ️ لم يتم إضافة شيء (يبدو أن البلوكات موجودة بالفعل)."
else
  echo "✅ تم حقن البلوكات الناقصة في $FILE"
fi
