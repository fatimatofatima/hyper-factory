#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "📌 Hyper Factory – DB Architect Task Orchestrator"
echo "================================================="
echo "⏰ $(date)"
echo "📄 DB: $DB_PATH"
echo ""

if [ ! -f "$DB_PATH" ]; then
    echo "❌ قاعدة البيانات غير موجودة: $DB_PATH"
    exit 1
fi

TABLES=$(sqlite3 "$DB_PATH" ".tables" 2>/dev/null || echo "")
if ! echo "$TABLES" | grep -qw "tasks"; then
    echo "❌ جدول tasks غير موجود – لا يمكن إنشاء مهام."
    exit 1
fi

if ! echo "$TABLES" | grep -qw "task_assignments"; then
    echo "❌ جدول task_assignments غير موجود – لا يمكن إسناد المهام."
    exit 1
fi

# إنشاء مهام DB Architect
echo "👷 العامل المستهدف: db_architect (مهندس قواعد البيانات)"
echo ""

# مهمة فحص صحة قاعدة البيانات
TASK_TYPE="db_health"
PRIORITY="high"
DESC="فحص صحة وسلامة قاعدة البيانات وإصلاح أي مشاكل"

sqlite3 "$DB_PATH" "
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
VALUES (
    datetime('now'), 
    'system:db_architect', 
    '$DESC', 
    '$TASK_TYPE', 
    '$PRIORITY', 
    'queued'
);
"

TASK_ID=$(sqlite3 "$DB_PATH" "SELECT last_insert_rowid();")

# إسناد المهمة إلى db_architect
sqlite3 "$DB_PATH" "
INSERT INTO task_assignments (task_id, agent_id, decision_reason, assigned_at, result_status)
VALUES (
    $TASK_ID,
    'db_architect',
    'مهمة صيانة دورية لقاعدة البيانات',
    datetime('now'),
    'pending'
);
"

echo "✅ تم إنشاء وإسناد المهمة:"
echo "   - نوع المهمة: $TASK_TYPE"
echo "   - الأولوية: $PRIORITY"
echo "   - رقم المهمة: $TASK_ID"
echo "   - تم الإسناد إلى: db_architect"

