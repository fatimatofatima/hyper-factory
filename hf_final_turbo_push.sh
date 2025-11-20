#!/usr/bin/env bash
set -Eeuo pipefail

DB="data/factory/factory.db"

echo "🎯 FINAL TURBO PUSH – إعادة توزيع ~10,000 مهمة من knowledge_spider"

if [[ ! -f "$DB" ]]; then
  echo "❌ قاعدة البيانات غير موجودة: $DB"
  exit 1
fi

sqlite3 "$DB" <<'SQL'
-- 3,000 → system_architect
UPDATE tasks
SET agent_id = 'system_architect'
WHERE agent_id = 'knowledge_spider' AND status = 'queued'
LIMIT 3000;

-- 3,000 → debug_expert
UPDATE tasks
SET agent_id = 'debug_expert'
WHERE agent_id = 'knowledge_spider' AND status = 'queued'
LIMIT 3000;

-- 2,000 → technical_coach
UPDATE tasks
SET agent_id = 'technical_coach'
WHERE agent_id = 'knowledge_spider' AND status = 'queued'
LIMIT 2000;

-- 1,000 → quality_engine
UPDATE tasks
SET agent_id = 'quality_engine'
WHERE agent_id = 'knowledge_spider' AND status = 'queued'
LIMIT 1000;

-- 1,000 → system_architect_boost_1
UPDATE tasks
SET agent_id = 'system_architect_boost_1'
WHERE agent_id = 'knowledge_spider' AND status = 'queued'
LIMIT 1000;
SQL

echo "✅ تم توزيع المهام على العوامل المتقدمة بنجاح"
