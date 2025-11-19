#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo "🧩 Hyper Factory – بناء خطة تطبيق الدروس وملفات diff"
echo "ROOT : $ROOT"
echo "=================================================="

if [ ! -x "$ROOT/tools/hf_apply_lessons_to_config.py" ]; then
  echo "[ERROR] سكربت Python غير موجود أو غير قابل للتنفيذ: tools/hf_apply_lessons_to_config.py"
  exit 1
fi

mkdir -p "$ROOT/ai/memory/lessons"
mkdir -p "$ROOT/config_changes"
mkdir -p "$ROOT/reports/management"

python3 "$ROOT/tools/hf_apply_lessons_to_config.py"

echo "=================================================="
echo "✅ اكتمل تنفيذ hf_run_apply_lessons.sh"
echo "راجع:"
echo "  - reports/management/lessons_apply_plan.md"
echo "  - config_changes/agents.diff"
echo "  - config_changes/factory.diff"
echo "=================================================="
