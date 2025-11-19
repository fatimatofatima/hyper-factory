#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-/root/hyper-factory}"

if [ ! -d "$ROOT" ]; then
  echo "❌ ROOT غير موجود: $ROOT"
  exit 1
fi

cd "$ROOT"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { printf " - %-40s %s\n" "$1" "$2"; }

create_dir() {
  local path="$1"
  if [ -d "$path" ]; then
    log "$path" "${YELLOW}EXISTS${NC}"
  else
    mkdir -p "$path"
    log "$path" "${GREEN}CREATED${NC}"
  fi
}

create_readme() {
  local dir="$1"
  local title="$2"
  local file="$dir/README.md"
  if [ ! -f "$file" ]; then
    cat > "$file" <<EOF2
# $title

هذا المجلد أنشئ تلقائيًا كبنية متقدمة لـ Hyper Factory.
- المسار: $dir
- تاريخ الإنشاء: $(date -Iseconds)
EOF2
  fi
}

echo "🏗️ Bootstrap للبنية المتقدمة في: $ROOT"
echo "========================================"

# Data Lakehouse
create_dir "data_lakehouse/raw"
create_dir "data_lakehouse/cleansed"
create_dir "data_lakehouse/semantic"
create_dir "data_lakehouse/serving"
create_readme "data_lakehouse" "Data Lakehouse"

# Factories
create_dir "factories/model_factory"
create_dir "factories/knowledge_factory"
create_dir "factories/quality_factory"
create_readme "factories" "Factories Root"

# Stack
create_dir "stack/gpu_cluster"
create_dir "stack/model_serving"
create_dir "stack/vector_db"
create_dir "stack/monitoring"
create_dir "stack/api_gateway"
create_readme "stack" "Advanced Stack (GPU / Serving / Vector DB)"

# Advanced systems
create_dir "ai/patterns"
create_dir "ai/quality"
create_dir "ai/memory/temporal"
create_dir "integrations"
create_readme "ai/patterns" "Patterns System"
create_readme "ai/quality" "Quality System"
create_readme "ai/memory/temporal" "Temporal Memory"
create_readme "integrations" "External Integrations"

echo
echo "✅ انتهى bootstrap البنية المتقدمة (بدون لمس أي بيانات موجودة)."
