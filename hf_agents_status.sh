#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="${ROOT_DIR}/data/knowledge/knowledge.db"

if [[ ! -f "${DB_PATH}" ]]; then
  echo "[HF-STATUS] DB غير موجود: ${DB_PATH}"
  echo "شغّل: ./hf_db_core_init.sh ثم ./hf_register_agents_from_yaml.sh"
  exit 1
fi

echo "=== Hyper Factory – Agents Status (from DB) ==="
echo

sqlite3 -column -header "${DB_PATH}" <<'SQL'
SELECT
  id,
  category,
  group_name,
  priority,
  CASE enabled WHEN 1 THEN 'ON' ELSE 'OFF' END AS enabled,
  datetime(created_at) AS created_at
FROM agents
ORDER BY category, priority, id;
SQL
