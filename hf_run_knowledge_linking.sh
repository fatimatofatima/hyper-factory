#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
KNOW_DB="$ROOT/data/knowledge/knowledge.db"
LOG_DIR="$ROOT/reports/db_architect"
mkdir -p "$LOG_DIR" "$(dirname "$KNOW_DB")"

TS="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$LOG_DIR/knowledge_linking_$TS.txt"

echo "🔗 Hyper Factory – Knowledge Linking Runner" | tee "$REPORT_FILE"
echo "==========================================" | tee -a "$REPORT_FILE"
echo "⏰ $(date)" | tee -a "$REPORT_FILE"
echo "📄 FACTORY DB : $DB_PATH" | tee -a "$REPORT_FILE"
echo "📄 KNOWLEDGE DB: $KNOW_DB" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ factory.db غير موجود: $DB_PATH" | tee -a "$REPORT_FILE"
    exit 1
fi

if [ ! -f "$KNOW_DB" ]; then
    echo "⚠️ knowledge.db غير موجود – سيتم إنشاؤه فارغاً للربط." | tee -a "$REPORT_FILE"
    sqlite3 "$KNOW_DB" "VACUUM;"
fi

echo "🔎 اختيار مهمة knowledge_linking مفتوحة لـ db_architect..." | tee -a "$REPORT_FILE"

TASK_ID="$(sqlite3 "$DB_PATH" "
SELECT t.id
FROM tasks t
JOIN task_assignments a ON a.task_id = t.id
WHERE t.task_type = 'knowledge_linking'
  AND t.source = 'system:db_architect'
  AND t.status IN ('queued','assigned')
  AND a.agent_id = 'db_architect'
  AND (a.result_status IS NULL OR a.result_status = '' OR a.result_status = 'pending')
ORDER BY t.id DESC
LIMIT 1;
")"

if [ -z "$TASK_ID" ]; then
    echo "ℹ️ لا توجد مهمة knowledge_linking مفتوحة لـ db_architect." | tee -a "$REPORT_FILE"
    exit 0
fi

echo "✅ تم اختيار مهمة ID=$TASK_ID" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "🔄 تحديث حالة المهمة إلى running..." | tee -a "$REPORT_FILE"
sqlite3 "$DB_PATH" "
UPDATE task_assignments
SET result_status = 'running',
    result_notes  = 'knowledge_linking started',
    assigned_at   = COALESCE(assigned_at, datetime('now'))
WHERE task_id = $TASK_ID
  AND agent_id = 'db_architect';

UPDATE tasks
SET status = 'running'
WHERE id = $TASK_ID;
"

echo "📊 قياس نقاط الربط بين factory.db و knowledge.db..." | tee -a "$REPORT_FILE"

FACT_TASKS="$(sqlite3 "$DB_PATH"  "SELECT COUNT(*) FROM tasks;")"
FACT_ASSIGN="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM task_assignments;")"
FACT_AGENTS="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM agents;")"

KNOW_HEALTH="$(sqlite3 "$KNOW_DB" "PRAGMA integrity_check;" 2>/dev/null || echo "no_db")"
KNOW_TABLES="$(sqlite3 "$KNOW_DB" "
SELECT COUNT(*) 
FROM sqlite_master 
WHERE type='table';
" 2>/dev/null || echo 0)"

KNOW_EVALS="$(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM performance_evaluations;" 2>/dev/null || echo 0)"
KNOW_TRAIN="$(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM training_recommendations;" 2>/dev/null || echo 0)"
KNOW_HEALTH_DB="$(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM db_health_reports;" 2>/dev/null || echo 0)"
KNOW_SCHEMA_R="$(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM schema_review_reports;" 2>/dev/null || echo 0)"

echo "🧾 أرقام أساسية:" | tee -a "$REPORT_FILE"
echo "  • factory.tasks              : $FACT_TASKS" | tee -a "$REPORT_FILE"
echo "  • factory.task_assignments   : $FACT_ASSIGN" | tee -a "$REPORT_FILE"
echo "  • factory.agents             : $FACT_AGENTS" | tee -a "$REPORT_FILE"
echo "  • knowledge.integrity_check  : $KNOW_HEALTH" | tee -a "$REPORT_FILE"
echo "  • knowledge.tables_count     : $KNOW_TABLES" | tee -a "$REPORT_FILE"
echo "  • knowledge.performance_eval : $KNOW_EVALS" | tee -a "$REPORT_FILE"
echo "  • knowledge.training_reco    : $KNOW_TRAIN" | tee -a "$REPORT_FILE"
echo "  • knowledge.db_health_reports: $KNOW_HEALTH_DB" | tee -a "$REPORT_FILE"
echo "  • knowledge.schema_reviews   : $KNOW_SCHEMA_R" | tee -a "$REPORT_FILE"

echo "" | tee -a "$REPORT_FILE"
echo "🧠 تسجيل ملخص الربط في knowledge.db..." | tee -a "$REPORT_FILE"

sqlite3 "$KNOW_DB" "
CREATE TABLE IF NOT EXISTS knowledge_linking_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER,
    factory_tasks INTEGER,
    factory_assignments INTEGER,
    factory_agents INTEGER,
    knowledge_tables INTEGER,
    knowledge_evaluations INTEGER,
    knowledge_trainings INTEGER,
    knowledge_db_health_reports INTEGER,
    knowledge_schema_reviews INTEGER,
    knowledge_integrity TEXT,
    report_file TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO knowledge_linking_reports (
    task_id,
    factory_tasks,
    factory_assignments,
    factory_agents,
    knowledge_tables,
    knowledge_evaluations,
    knowledge_trainings,
    knowledge_db_health_reports,
    knowledge_schema_reviews,
    knowledge_integrity,
    report_file
) VALUES (
    $TASK_ID,
    $FACT_TASKS,
    $FACT_ASSIGN,
    $FACT_AGENTS,
    $KNOW_TABLES,
    $KNOW_EVALS,
    $KNOW_TRAIN,
    $KNOW_HEALTH_DB,
    $KNOW_SCHEMA_R,
    '$KNOW_HEALTH',
    '$REPORT_FILE'
);
"

sqlite3 "$DB_PATH" "
UPDATE task_assignments
SET result_status = 'success',
    result_notes  = 'knowledge_linking: linked factory + knowledge, report=$REPORT_FILE',
    completed_at  = datetime('now')
WHERE task_id = $TASK_ID
  AND agent_id = 'db_architect';

UPDATE tasks
SET status = 'done'
WHERE id = $TASK_ID;
"

echo "" | tee -a "$REPORT_FILE"
echo "✅ knowledge_linking انتهت بنجاح" | tee -a "$REPORT_FILE"
echo "📄 التقرير: $REPORT_FILE" | tee -a "$REPORT_FILE"
