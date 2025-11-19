#!/usr/bin/env bash
# hf_run_knowledge_spider.sh
# تشغيل Knowledge Spider وتجميع المعرفة في SQLite

set -euo pipefail

ROOT="/root/hyper-factory"
SCRIPT="$ROOT/tools/hf_knowledge_spider.py"

echo "📁 ROOT   : $ROOT"
echo "📄 SCRIPT : $SCRIPT"
echo "----------------------------------------"

cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 غير متوفر في PATH."
  exit 1
fi

if [[ ! -f "$SCRIPT" ]]; then
  echo "❌ ملف hf_knowledge_spider.py غير موجود: $SCRIPT"
  exit 1
fi

python3 "$SCRIPT"

echo "----------------------------------------"
echo "📌 لمراجعة إحصائيات المعرفة:"
echo "  sqlite3 data/knowledge/knowledge.db 'SELECT item_type, COUNT(*) FROM knowledge_items GROUP BY item_type;' || true"
