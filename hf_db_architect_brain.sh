#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
KNOW_DB="$ROOT/data/knowledge/knowledge.db"
LOG_DIR="$ROOT/reports/db_architect"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$LOG_DIR/db_architect_report_$TS.txt"

mkdir -p "$LOG_DIR"
mkdir -p "$(dirname "$KNOW_DB")"

echo "🧠 Hyper Factory – DB Architect Brain" | tee "$OUT_FILE"
echo "======================================" | tee -a "$OUT_FILE"
echo "⏰ $(date)" | tee -a "$OUT_FILE"
echo "📄 Factory DB: $DB_PATH" | tee -a "$OUT_FILE"
echo "📄 Knowledge DB: $KNOW_DB" | tee -a "$OUT_FILE"
echo "" | tee -a "$OUT_FILE"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ قاعدة بيانات المصنع غير موجودة: $DB_PATH" | tee -a "$OUT_FILE"
    exit 1
fi

# تجهيز جداول المعرفة البنيوية في knowledge.db
sqlite3 "$KNOW_DB" "
CREATE TABLE IF NOT EXISTS knowledge_base (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    content TEXT,
    source_type TEXT,
    quality_score INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS db_architect_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_ts TEXT,
    integrity_result TEXT,
    tables_total INTEGER,
    core_tables_missing INTEGER,
    core_tables_with_rows INTEGER,
    notes TEXT,
    report_path TEXT
);
"

echo "🔎 PRAGMA integrity_check:" | tee -a "$OUT_FILE"
INTEGRITY_RESULT=$(sqlite3 "$DB_PATH" "PRAGMA integrity_check;")
echo "  $INTEGRITY_RESULT" | tee -a "$OUT_FILE"
echo "" | tee -a "$OUT_FILE"

echo "📋 جميع الجداول في المصنع:" | tee -a "$OUT_FILE"
sqlite3 "$DB_PATH" ".tables" | sed 's/^/  - /' | tee -a "$OUT_FILE"
echo "" | tee -a "$OUT_FILE"

TOTAL_TABLES=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';")
echo "📊 إجمالي عدد الجداول: $TOTAL_TABLES" | tee -a "$OUT_FILE"
echo "" | tee -a "$OUT_FILE"

# الجداول الأساسية التي نهتم بها في المصنع
CORE_TABLES=(
  agents
  tasks
  task_assignments
  skills
  tracks
  track_phases
  user_skills
  user_tracks
  learning_log
  system_settings
  daily_reports
)

CORE_MISSING=0
CORE_WITH_ROWS=0

echo "📊 فحص هيكل وحجم الجداول الأساسية:" | tee -a "$OUT_FILE"
for T in "${CORE_TABLES[@]}"; do
    echo "" | tee -a "$OUT_FILE"
    echo "-----------------------------" | tee -a "$OUT_FILE"
    echo "📌 Table: $T" | tee -a "$OUT_FILE"

    EXISTS=$(sqlite3 "$DB_PATH" "
        SELECT COUNT(*) 
        FROM sqlite_master 
        WHERE type='table' AND name='$T';
    ")

    if [ "$EXISTS" != "1" ]; then
        echo "  ⚠️ الجدول غير موجود" | tee -a "$OUT_FILE"
        CORE_MISSING=$((CORE_MISSING + 1))
        continue
    fi

    echo "  ▸ الهيكل:" | tee -a "$OUT_FILE"
    sqlite3 "$DB_PATH" "PRAGMA table_info($T);" | sed 's/^/    /' | tee -a "$OUT_FILE"

    ROW_COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM $T;")
    echo "  ▸ عدد السجلات: $ROW_COUNT" | tee -a "$OUT_FILE"

    if [ "$ROW_COUNT" -gt 0 ]; then
        CORE_WITH_ROWS=$((CORE_WITH_ROWS + 1))
    fi
done

echo "" | tee -a "$OUT_FILE"
echo "📈 لمحة سريعة عن أداء العمال (agents):" | tee -a "$OUT_FILE"
sqlite3 "$DB_PATH" -header -column "
SELECT
    id,
    display_name,
    family,
    level,
    success_rate,
    total_runs
FROM agents
ORDER BY success_rate DESC, total_runs DESC
LIMIT 15;
" 2>>"$OUT_FILE" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"
echo "📌 ملخص تحليلي مبدئي:" | tee -a "$OUT_FILE"
echo "- نتيجة integrity_check: $INTEGRITY_RESULT" | tee -a "$OUT_FILE"
echo "- إجمالي الجداول: $TOTAL_TABLES" | tee -a "$OUT_FILE"
echo "- عدد الجداول الأساسية الناقصة: $CORE_MISSING" | tee -a "$OUT_FILE"
echo "- عدد الجداول الأساسية التي تحتوي بيانات: $CORE_WITH_ROWS" | tee -a "$OUT_FILE"

# تسجيل هذه الدورة في knowledge.db (db_architect_runs)
sqlite3 "$KNOW_DB" "
INSERT INTO db_architect_runs (
    run_ts,
    integrity_result,
    tables_total,
    core_tables_missing,
    core_tables_with_rows,
    notes,
    report_path
) VALUES (
    datetime('now'),
    '$INTEGRITY_RESULT',
    $TOTAL_TABLES,
    $CORE_MISSING,
    $CORE_WITH_ROWS,
    'auto-run from hf_db_architect_brain.sh',
    '$OUT_FILE'
);
"

echo "" | tee -a "$OUT_FILE"
echo "✅ DB Architect Brain run finished." | tee -a "$OUT_FILE"
echo "   Report: $OUT_FILE" | tee -a "$OUT_FILE"
