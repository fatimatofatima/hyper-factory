#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
KNOW_DB="$ROOT/data/knowledge/knowledge.db"
LOG_DIR="$ROOT/reports/db_architect"
mkdir -p "$LOG_DIR" "$(dirname "$KNOW_DB")"

TS="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$LOG_DIR/schema_review_$TS.txt"

echo "📐 Hyper Factory – Schema Review Runner" | tee "$REPORT_FILE"
echo "=======================================" | tee -a "$REPORT_FILE"
echo "⏰ $(date)" | tee -a "$REPORT_FILE"
echo "📄 DB: $DB_PATH" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ factory.db غير موجود: $DB_PATH" | tee -a "$REPORT_FILE"
    exit 1
fi

echo "🔎 اختيار مهمة schema_review مفتوحة لـ db_architect..." | tee -a "$REPORT_FILE"

TASK_ID="$(sqlite3 "$DB_PATH" "
SELECT t.id
FROM tasks t
JOIN task_assignments a ON a.task_id = t.id
WHERE t.task_type = 'schema_review'
  AND t.source = 'system:db_architect'
  AND t.status IN ('queued','assigned')
  AND a.agent_id = 'db_architect'
  AND (a.result_status IS NULL OR a.result_status = '' OR a.result_status = 'pending')
ORDER BY t.id DESC
LIMIT 1;
")"

if [ -z "$TASK_ID" ]; then
    echo "ℹ️ لا توجد مهمة schema_review مفتوحة لـ db_architect." | tee -a "$REPORT_FILE"
    exit 0
fi

echo "✅ تم اختيار مهمة ID=$TASK_ID" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "🔄 تحديث حالة المهمة إلى running..." | tee -a "$REPORT_FILE"
sqlite3 "$DB_PATH" "
UPDATE task_assignments
SET result_status = 'running',
    result_notes  = 'schema_review started',
    assigned_at   = COALESCE(assigned_at, datetime('now'))
WHERE task_id = $TASK_ID
  AND agent_id = 'db_architect';

UPDATE tasks
SET status = 'running'
WHERE id = $TASK_ID;
"

echo "📋 تحليل الجداول الأساسية (agents, tasks, task_assignments, skills, learning_log, daily_reports)..." | tee -a "$REPORT_FILE"

KEY_TABLES="agents tasks task_assignments skills learning_log daily_reports"

REVIEWED=0
for T in $KEY_TABLES; do
    echo "-----------------------------" | tee -a "$REPORT_FILE"
    echo "📌 Table: $T" | tee -a "$REPORT_FILE"

    INFO="$(sqlite3 "$DB_PATH" "PRAGMA table_info('$T');" 2>/dev/null || true)"
    if [ -z "$INFO" ]; then
        echo "  ⚠️ الجدول غير موجود" | tee -a "$REPORT_FILE"
        continue
    fi

    echo "  ▸ الهيكل:" | tee -a "$REPORT_FILE"
    echo "$INFO" | sed 's/^/    /' | tee -a "$REPORT_FILE"

    ROWS="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM '$T';" 2>/dev/null || echo "ERR")"
    echo "  ▸ عدد السجلات: $ROWS" | tee -a "$REPORT_FILE"

    IDX="$(sqlite3 "$DB_PATH" "PRAGMA index_list('$T');" 2>/dev/null || true)"
    if [ -n "$IDX" ]; then
        echo "  ▸ الفهارس:" | tee -a "$REPORT_FILE"
        echo "$IDX" | sed 's/^/    /' | tee -a "$REPORT_FILE"
    else
        echo "  ▸ لا توجد فهارس معرفة (قد يلزم تحسين لاحقاً)" | tee -a "$REPORT_FILE"
    fi

    REVIEWED=$((REVIEWED + 1))
done

echo "" | tee -a "$REPORT_FILE"
echo "📊 عدد الجداول التي تمت مراجعتها: $REVIEWED" | tee -a "$REPORT_FILE"

echo "🧠 تخزين ملخص schema_review في knowledge.db..." | tee -a "$REPORT_FILE"

sqlite3 "$KNOW_DB" "
CREATE TABLE IF NOT EXISTS schema_review_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER,
    db_path TEXT,
    reviewed_tables INTEGER,
    report_file TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO schema_review_reports (task_id, db_path, reviewed_tables, report_file)
VALUES ($TASK_ID, '$DB_PATH', $REVIEWED, '$REPORT_FILE');
"

sqlite3 "$DB_PATH" "
UPDATE task_assignments
SET result_status = 'success',
    result_notes  = 'schema_review: reviewed_tables=$REVIEWED, report=$REPORT_FILE',
    completed_at  = datetime('now')
WHERE task_id = $TASK_ID
  AND agent_id = 'db_architect';

UPDATE tasks
SET status = 'done'
WHERE id = $TASK_ID;
"

echo "" | tee -a "$REPORT_FILE"
echo "✅ schema_review انتهت بنجاح" | tee -a "$REPORT_FILE"
echo "📄 التقرير: $REPORT_FILE" | tee -a "$REPORT_FILE"
