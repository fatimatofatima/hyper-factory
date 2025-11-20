#!/usr/bin/env bash
# Hyper Factory – KPIs & Skills Feedback Viewer

set -euo pipefail

ROOT="/root/hyper-factory"
DB="$ROOT/data/factory/factory.db"

echo "📊 Hyper Factory – KPIs & Skills Feedback"

if [ ! -f "$DB" ]; then
    echo "⚠️ قاعدة البيانات غير موجودة: $DB"
    exit 1
fi

echo ""
echo "=== 1) KPIs للعوامل (agents) – مستوى المهارات والأداء ==="
sqlite3 -header -column "$DB" "
SELECT
    name          AS agent,
    family        AS family,
    role          AS role,
    level         AS level,
    printf('%.1f', success_rate) AS success_rate,
    total_runs    AS runs
FROM agents
ORDER BY success_rate DESC, total_runs DESC
LIMIT 30;
"

echo ""
echo "=== 2) performance_metrics – آخر 30 قياس أداء ==="
sqlite3 -header -column "$DB" "
SELECT
    id,
    agent_id,
    metric_type,
    printf('%.2f', metric_value) AS value,
    substr(timestamp, 1, 19)     AS ts,
    description
FROM performance_metrics
ORDER BY id DESC
LIMIT 30;
"

echo ""
echo "=== 3) feedback_data – آخر 30 Feedback (لو موجودة) ==="
sqlite3 -header -column "$DB" "
SELECT
    id,
    agent_id,
    COALESCE(metric_type, '')         AS metric_type,
    printf('%.2f', COALESCE(metric_value, 0)) AS value,
    substr(timestamp, 1, 19)         AS ts,
    COALESCE(notes, '')              AS notes
FROM feedback_data
ORDER BY id DESC
LIMIT 30;
"
