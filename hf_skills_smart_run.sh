#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

DB_PATH="$ROOT/data/factory/factory.db"
RULES_YAML="$ROOT/config/skills_task_rules.yaml"
AUTO_PY="$ROOT/tools/hf_skills_autoupdate.py"
CLI_SKILLS="$ROOT/hf_skills_cli.sh"

echo "🤖 Hyper Factory – Skills Smart Run"
echo "==================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

# التأكد من وجود قاعدة البيانات
if [ ! -f "$DB_PATH" ]; then
  echo "🧱 لا توجد قاعدة بيانات للمصنع – سيتم تشغيل init-db..."
  ./hf_factory_cli.sh init-db
fi

# إنشاء ملف قواعد المهارات لو غير موجود
if [ ! -f "$RULES_YAML" ]; then
  echo "📝 إنشاء ملف قواعد المهارات الافتراضي: $RULES_YAML"
  mkdir -p "$ROOT/config"
  cat > "$RULES_YAML" << 'YAML'
# Hyper Factory – Skills Task Rules
# عدّل skill_id / track_id بما يناسب skills_tracks_backend_complete.yaml

default_user: angel

task_type_rules:
  debug:
    skill_id: debug_skills
    skill_delta: 5
    track_id: backend_junior_complete
    track_delta: 2.5

  architecture:
    skill_id: system_design
    skill_delta: 5
    track_id: backend_junior_complete
    track_delta: 3.0

  coaching:
    skill_id: coaching
    skill_delta: 3
    track_id: backend_junior_complete
    track_delta: 1.5
YAML
fi

if [ ! -x "$AUTO_PY" ]; then
  echo "❌ tools/hf_skills_autoupdate.py غير موجود أو غير قابل للتنفيذ."
  exit 1
fi

echo "⚙️ مزامنة المهارات مع التعيينات المنجزة..."
python3 "$AUTO_PY" sync

echo ""
if [ -x "$CLI_SKILLS" ]; then
  echo "📊 عرض حالة المستخدم الافتراضي من ملف القواعد:"
  default_user=$(grep -E '^default_user:' "$RULES_YAML" | awk -F':' '{gsub(/ /,"",$2); print $2}')
  if [ -n "$default_user" ]; then
    ./hf_skills_cli.sh show-user "$default_user" || true
  fi
fi

echo "✅ Skills Smart Run انتهت."
