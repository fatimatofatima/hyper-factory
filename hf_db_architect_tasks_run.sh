#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "👷 Hyper Factory – DB Architect Tasks Runner"
echo "============================================"
echo "⏰ $(date)"
echo "📄 DB: $DB_PATH"
echo ""

if [ ! -f "$DB_PATH" ]; then
    echo "❌ factory.db غير موجود: $DB_PATH"
    exit 1
fi

TABLES=$(sqlite3 "$DB_PATH" ".tables" 2>/dev/null || echo "")
if ! echo "$TABLES" | grep -qw "tasks"; then
    echo "❌ جدول tasks غير موجود – لا يمكن تسجيل المهام."
    exit 1
fi
if ! echo "$TABLES" | grep -qw "task_assignments"; then
    echo "❌ جدول task_assignments غير موجود – لا يمكن تسجيل الإسناد."
    exit 1
fi
if ! echo "$TABLES" | grep -qw "agents"; then
    echo "❌ جدول agents غير موجود – لا يمكن التحقق من db_architect."
    exit 1
fi

EXISTS_AGENT=$(sqlite3 "$DB_PATH" "
    SELECT COUNT(*) FROM agents WHERE id = 'db_architect';
")
if [ "$EXISTS_AGENT" -eq 0 ]; then
    echo "⚠️ العامل db_architect غير مسجل – شغّل hf_register_core_agents.sh أولاً."
    exit 1
fi

declare -a TASK_TYPES=("db_health" "schema_review" "knowledge_linking")

for TTYPE in "${TASK_TYPES[@]}"; do
    echo "📝 إنشاء وتنفيذ مهمة: $TTYPE"

    DESC="DB Architect auto task: $TTYPE @ $(date +%Y-%m-%d_%H:%M:%S)"

    sqlite3 "$DB_PATH" "
    INSERT INTO tasks (type, family, priority, status, description, created_at, updated_at)
    VALUES (
        '$TTYPE',
        'data_platform',
        'high',
        'done',
        '$DESC',
        datetime('now'),
        datetime('now')
    );
    "
    TASK_ID=$(sqlite3 "$DB_PATH" "SELECT last_insert_rowid();")

    sqlite3 "$DB_PATH" "
    INSERT INTO task_assignments (
        task_id,
        agent_id,
        assigned_at,
        started_at,
        finished_at,
        status,
        notes
    ) VALUES (
        $TASK_ID,
        'db_architect',
        datetime('now'),
        datetime('now'),
        datetime('now'),
        'done',
        'auto-run via hf_db_architect_tasks_run.sh'
    );
    "

    echo "   ✅ تم تسجيل المهمة $TTYPE بـ task_id = $TASK_ID لصالح db_architect"
done

echo ""
echo "🧠 تشغيل عقل db_architect لفحص فعلي لقاعدة البيانات..."
"$ROOT/hf_db_architect_brain.sh"

echo ""
echo "📊 ملخص سريع بعد الدورة:"
sqlite3 "$DB_PATH" -header -column "
SELECT 
    type,
    family,
    priority,
    status,
    COUNT(*) AS cnt
FROM tasks
GROUP BY type, family, priority, status
ORDER BY cnt DESC;
"

echo ""
echo "✅ DB Architect tasks run finished."
