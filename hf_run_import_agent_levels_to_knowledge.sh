#!/usr/bin/env bash
# hf_run_import_agent_levels_to_knowledge.sh
# تشغيل استيراد agent_level إلى knowledge.db + عرض إحصائية سريعة

set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "============================================"
echo "📥 Hyper Factory – Import Agent Levels to Knowledge"
echo "📁 ROOT : $ROOT"
echo "============================================"

if [[ ! -x "tools/hf_import_agent_levels_to_knowledge.py" ]]; then
  echo "⚠️ tools/hf_import_agent_levels_to_knowledge.py غير موجود أو غير قابل للتنفيذ."
  exit 1
fi

python3 tools/hf_import_agent_levels_to_knowledge.py

echo
echo "----------- ملخص أنواع عناصر المعرفة -----------"
if command -v sqlite3 >/dev/null 2>&1; then
  sqlite3 data/knowledge/knowledge.db \
    'SELECT item_type, COUNT(*) FROM knowledge_items GROUP BY item_type;'
else
  echo "ℹ️ sqlite3 غير متوفر؛ يمكنك فحص قاعدة البيانات يدويًا."
fi
