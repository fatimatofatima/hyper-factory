#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="${ROOT_DIR}/data/knowledge"
DB_PATH="${DB_DIR}/knowledge.db"

mkdir -p "${DB_DIR}"

# حذف ملف $DB_PATH الوهمي لو موجود في جذر المشروع (غلط سكربت قديم)
if [[ -f "${ROOT_DIR}/\$DB_PATH" ]]; then
  echo "[WARN] Removing stray file: ${ROOT_DIR}/\$DB_PATH"
  rm -f "${ROOT_DIR}/\$DB_PATH"
fi

echo "[HF-DB] Using DB: ${DB_PATH}"

# إنشاء الجداول الأساسية للعمال
sqlite3 "${DB_PATH}" <<'SQL'
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;

CREATE TABLE IF NOT EXISTS agents (
  id           TEXT PRIMARY KEY,
  display_name TEXT,
  category     TEXT,
  role         TEXT,
  group_name   TEXT,
  priority     INTEGER,
  enabled      INTEGER,
  script       TEXT,
  created_at   TEXT DEFAULT (datetime('now')),
  updated_at   TEXT DEFAULT (datetime('now'))
);

CREATE TRIGGER IF NOT EXISTS trg_agents_updated_at
AFTER UPDATE ON agents
FOR EACH ROW
BEGIN
  UPDATE agents SET updated_at = datetime('now') WHERE id = OLD.id;
END;
SQL

echo "[HF-DB] Schema ready."
echo "[HF-DB] Current agents count:"
sqlite3 "${DB_PATH}" "SELECT COUNT(*) FROM agents;"
