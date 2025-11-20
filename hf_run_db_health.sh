#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
KNOW_DB="$ROOT/data/knowledge/knowledge.db"
LOG_DIR="$ROOT/reports/db_architect"
mkdir -p "$LOG_DIR" "$(dirname "$KNOW_DB")"

TS="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$LOG_DIR/db_health_$TS.txt"

echo "🩺 Hyper Factory – DB Health Runner" | tee "$REPORT_FILE"
echo "===================================" | tee -a "$REPORT_FILE"
echo "⏰ $(date)" | tee -a "$REPORT_FILE"
echo "📄 DB: $DB_PATH" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ factory.db غير موجود: $DB_PATH" | tee -a "$REPORT_FILE"
    exit 1
fi

echo "🔎 اختيار مهمة db_health مفتوحة لـ db_architect..." | tee -a "$REPORT_FILE"

TASK_ID="$(sqlite3 "$DB_PATH" "
SELECT t.id
FROM tasks t
JOIN task_assignments a ON a.task_id = t.id
WHERE t.task_type = 'db_health'
  AND t.source = 'system:db_architect'
  AND t.status IN ('queued','assigned')
  AND a.agent_id = 'db_architect'
  AND (a.result_status IS NULL OR a.result_status = '' OR a.result_status = 'pending')
ORDER BY t.id DESC
LIMIT 1;
")"

if [ -z "$TASK_ID" ]; then
    echo "ℹ️ لا توجد مهمة db_health مفتوحة لـ db_architect." | tee -a "$REPORT_FILE"
    exit 0
fi

echo "✅ تم اختيار مهمة ID=$TASK_ID" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "🔄 تحديث حالة المهمة إلى running..." | tee -a "$REPORT_FILE"
sqlite3 "$DB_PATH" "
UPDATE task_assignments
SET result_status = 'running',
    result_notes  = 'db_health started',
    assigned_at   = COALESCE(assigned_at, datetime('now'))
WHERE task_id = $TASK_ID
  AND agent_id = 'db_architect';

UPDATE tasks
SET status = 'running'
WHERE id = $TASK_ID;
"

echo "🧪 PRAGMA integrity_check..." | tee -a "$REPORT_FILE"
HEALTH="$(sqlite3 "$DB_PATH" 'PRAGMA integrity_check;')"
echo "   integrity_check = $HEALTH" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "📋 قائمة الجداول وأحجامها:" | tee -a "$REPORT_FILE"
TABLES="$(sqlite3 "$DB_PATH" "
SELECT name
FROM sqlite_master
WHERE type = 'table'
ORDER BY name;
")"

TABLE_COUNT=0
for T in $TABLES; do
    ROWS="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM \"$T\";")" || ROWS="ERR"
    printf "  - %-20s : %s rows\n" "$T" "$ROWS" | tee -a "$REPORT_FILE"
    TABLE_COUNT=$((TABLE_COUNT + 1))
done

echo "" | tee -a "$REPORT_FILE"
echo "📊 إجمالي عدد الجداول: $TABLE_COUNT" | tee -a "$REPORT_FILE"

STATUS="success"
TASK_STATUS="done"
if [ "$HEALTH" != "ok" ]; then
    STATUS="failed"
    TASK_STATUS="failed"
    echo "⚠️ integrity_check ليست ok → سيتم اعتبار المهمة failed" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo "🧠 تسجيل تقرير الصحة في knowledge.db..." | tee -a "$REPORT_FILE"

sqlite3 "$KNOW_DB" "
CREATE TABLE IF NOT EXISTS db_health_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER,
    db_path TEXT,
    integrity_status TEXT,
    tables_count INTEGER,
    report_file TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO db_health_reports (task_id, db_path, integrity_status, tables_count, report_file)
VALUES ($TASK_ID, '$DB_PATH', '$HEALTH', $TABLE_COUNT, '$REPORT_FILE');
"

echo "🔚 تحديث حالة المهمة في factory.db..." | tee -a "$REPORT_FILE"

sqlite3 "$DB_PATH" "
UPDATE task_assignments
SET result_status = '$STATUS',
    result_notes  = 'db_health: integrity=$HEALTH, report=$REPORT_FILE',
    completed_at  = datetime('now')
WHERE task_id = $TASK_ID
  AND agent_id = 'db_architect';

UPDATE tasks
SET status = '$TASK_STATUS'
WHERE id = $TASK_ID;
"

echo "" | tee -a "$REPORT_FILE"
echo "✅ db_health انتهت بحالة: $STATUS" | tee -a "$REPORT_FILE"
echo "📄 التقرير: $REPORT_FILE" | tee -a "$REPORT_FILE"
