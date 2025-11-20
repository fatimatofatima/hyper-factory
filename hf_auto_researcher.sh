#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
KNOW_DB="$ROOT/data/knowledge/knowledge.db"

echo "🔍 Hyper Factory – Auto Researcher"
echo "==================================="
echo "⏰ $(date)"
echo "📄 FACTORY DB : $DB_PATH"
echo "📄 KNOWLEDGE DB: $KNOW_DB"
echo ""

if [ ! -f "$DB_PATH" ]; then
    echo "❌ factory.db غير موجود: $DB_PATH"
    exit 1
fi

mkdir -p "$(dirname "$KNOW_DB")"

sqlite3 "$KNOW_DB" "
ATTACH DATABASE '$DB_PATH' AS factory;

-- جدول مواضيع البحث
CREATE TABLE IF NOT EXISTS research_topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT UNIQUE NOT NULL,
    source TEXT,
    importance TEXT,
    tasks_count INTEGER DEFAULT 0,
    last_seen TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    last_updated TEXT DEFAULT CURRENT_TIMESTAMP
);

-- جدول المعرفة العامة
CREATE TABLE IF NOT EXISTS knowledge_base (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    content TEXT,
    source_type TEXT,
    quality_score INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    last_updated TEXT DEFAULT CURRENT_TIMESTAMP
);

-- مواضيع بحث مبنية على أنواع المهام في المصنع
INSERT INTO research_topics (topic, source, importance, tasks_count, last_seen, last_updated)
SELECT
    'factory.task_type.' || t.task_type AS topic,
    'factory.tasks' AS source,
    CASE 
        WHEN COUNT(*) >= 80 THEN 'critical'
        WHEN COUNT(*) >= 40 THEN 'high'
        ELSE 'normal'
    END AS importance,
    COUNT(*) AS tasks_count,
    MAX(t.created_at) AS last_seen,
    CURRENT_TIMESTAMP AS last_updated
FROM factory.tasks t
GROUP BY t.task_type
ON CONFLICT(topic) DO UPDATE SET
    tasks_count    = excluded.tasks_count,
    importance     = excluded.importance,
    last_seen      = excluded.last_seen,
    last_updated   = excluded.last_updated;

-- ملخص عام لحمل المصنع
INSERT INTO knowledge_base (topic, content, source_type, quality_score, last_updated)
VALUES (
    'factory.load_overview',
    'ملخص تلقائي: إجمالي المهام = ' ||
        (SELECT COUNT(*) FROM factory.tasks) ||
    ', المكتملة = ' ||
        (SELECT COUNT(*) FROM factory.tasks WHERE status = ''done'') ||
    ', الفاشلة = ' ||
        (SELECT COUNT(*) FROM factory.tasks WHERE status = ''failed'') ||
    ', في الطابور = ' ||
        (SELECT COUNT(*) FROM factory.tasks WHERE status IN (''queued'',''assigned'')),
    'auto_researcher',
    85,
    CURRENT_TIMESTAMP
);
"

echo "✅ Auto Researcher اكتمل (research_topics + knowledge_base تم تحديثهم)"
