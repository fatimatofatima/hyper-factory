#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-/root/hyper-factory}"

[ -d "$ROOT" ] || { echo "❌ ROOT غير موجود: $ROOT"; exit 1; }
cd "$ROOT"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { printf " - %-45s %s\n" "$1" "$2"; }

echo "⚙️ Wiring الأنظمة المتقدمة في: $ROOT"
echo "======================================"

# تنبيه لو في مجلدات ناقصة
for d in "ai" "ai/memory" "ai/quality" "ai/patterns" "ai/memory/temporal" "integrations"; do
  if [ ! -d "$d" ]; then
    echo -e "${YELLOW}⚠️ المجلد مفقود: $d (يفضّل تشغيل hf_bootstrap_advanced_layout أولاً)${NC}"
  fi
done

# Quality wiring (symlinks من memory → quality)
if [ -f "ai/memory/quality.json" ] && [ ! -e "ai/quality/quality.json" ]; then
  ln -s ../memory/quality.json ai/quality/quality.json
  log "ai/quality/quality.json" "${GREEN}SYMLINK_CREATED${NC}"
else
  log "ai/quality/quality.json" "${YELLOW}SKIP${NC}"
fi

if [ -f "ai/memory/quality_status.json" ] && [ ! -e "ai/quality/quality_status.json" ]; then
  ln -s ../memory/quality_status.json ai/quality/quality_status.json
  log "ai/quality/quality_status.json" "${GREEN}SYMLINK_CREATED${NC}"
else
  log "ai/quality/quality_status.json" "${YELLOW}SKIP${NC}"
fi

if [ -f "ai/memory/quality_report.txt" ] && [ ! -e "ai/quality/quality_report.txt" ]; then
  ln -s ../memory/quality_report.txt ai/quality/quality_report.txt
  log "ai/quality/quality_report.txt" "${GREEN}SYMLINK_CREATED${NC}"
else
  log "ai/quality/quality_report.txt" "${YELLOW}SKIP${NC}"
fi

# Patterns index (فهرس فقط من insights + smart_actions)
if [ ! -f "ai/patterns/patterns_index.json" ]; then
  mkdir -p ai/patterns
  cat > "ai/patterns/patterns_index.json" <<EOF2
{
  "generated_at": "$(date -Iseconds)",
  "source_files": [
    "ai/memory/insights.json",
    "ai/memory/smart_actions.json"
  ],
  "note": "هذا ملف فهرس يربط بين الذاكرة (insights/smart_actions) ونظام الأنماط. الاستخراج الآلي للأنماط لم يُنفذ بعد."
}
EOF2
  log "ai/patterns/patterns_index.json" "${GREEN}CREATED${NC}"
else
  log "ai/patterns/patterns_index.json" "${YELLOW}EXISTS${NC}"
fi

# Temporal memory seed
if [ ! -f "ai/memory/temporal/seed_state.json" ]; then
  mkdir -p ai/memory/temporal
  cat > "ai/memory/temporal/seed_state.json" <<EOF3
{
  "generated_at": "$(date -Iseconds)",
  "schema": "v1",
  "description": "بذرة لتخزين تطور المستخدمين/العمال بمرور الوقت. يمكن توسيعها لاحقًا.",
  "users": []
}
EOF3
  log "ai/memory/temporal/seed_state.json" "${GREEN}CREATED${NC}"
else
  log "ai/memory/temporal/seed_state.json" "${YELLOW}EXISTS${NC}"
fi

# Integrations manifest (template فقط – لا يفعّل أي شيء)
if [ ! -f "integrations/integrations_manifest.yaml" ]; then
  mkdir -p integrations
  cat > "integrations/integrations_manifest.yaml" <<EOF4
# Hyper Factory – Integrations Manifest (template)
# هذا الملف لا يفعّل أي تكامل تلقائيًا؛ فقط هيكل جاهز للربط لاحقًا.

external_systems:
  smartfriend_suite:
    enabled: false
    notes: "اربط هنا بين Hyper Factory و SmartFriend Suite (health, memory, knowledge)."
  ffactory:
    enabled: false
    notes: "تكامل اختياري مع ffactory / stack الخارجي."

updated_at: "$(date -Iseconds)"
EOF4
  log "integrations/integrations_manifest.yaml" "${GREEN}CREATED${NC}"
else
  log "integrations/integrations_manifest.yaml" "${YELLOW}EXISTS${NC}"
fi

echo
echo "✅ wiring الأنظمة المتقدمة انتهى (symlinks + templates فقط، بدون تعديل ملفات قائمة)."
