#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/knowledge/knowledge.db"

echo "=================================================="
echo "📤 Hyper Factory – تصدير الدروس من knowledge.db → ai/memory/lessons"
echo "ROOT : $ROOT"
echo "DB   : $DB_PATH"
echo "=================================================="

if [ ! -f "$DB_PATH" ]; then
  echo "[ERROR] قاعدة المعرفة غير موجودة: $DB_PATH"
  exit 1
fi

if [ ! -x "$ROOT/tools/hf_export_lessons_from_db.py" ]; then
  echo "[ERROR] سكربت Python غير موجود أو غير قابل للتنفيذ: tools/hf_export_lessons_from_db.py"
  exit 1
fi

mkdir -p "$ROOT/ai/memory/lessons"

python3 "$ROOT/tools/hf_export_lessons_from_db.py"

echo "=================================================="
echo "✅ اكتمل تنفيذ hf_run_export_lessons.sh"
echo "راجع:"
echo "  - ai/memory/lessons/*.json"
echo "  - reports/management/lessons_export_report.txt"
echo "=================================================="
