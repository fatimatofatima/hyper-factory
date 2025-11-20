#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
QUALITY_PY="$ROOT/tools/hf_factory_quality_engine.py"

echo "🧪 Hyper Factory – Quality Refresh"
echo "=================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo "📄 DB  : $DB_PATH"
echo ""

if [ ! -f "$DB_PATH" ]; then
  echo "❌ قاعدة بيانات المصنع غير موجودة."
  echo "   شغّل أولًا: ./hf_factory_cli.sh init-db"
  exit 1
fi

if [ ! -x "$QUALITY_PY" ]; then
  echo "❌ محرك الجودة غير موجود أو غير قابل للتنفيذ: $QUALITY_PY"
  exit 1
fi

echo "🔁 تحديث مؤشرات الأداء في جدول agents من task_assignments..."
python3 "$QUALITY_PY"

echo ""
echo "📌 لمحة سريعة بعد التحديث:"
sqlite3 "$DB_PATH" "
  SELECT
    id,
    COALESCE(display_name, ''),
    COALESCE(total_runs,0),
    COALESCE(success_runs,0),
    COALESCE(failed_runs,0),
    printf('%.2f', COALESCE(success_rate,0.0))
  FROM agents
  ORDER BY total_runs DESC;
"

echo "✅ Quality Refresh انتهى."
