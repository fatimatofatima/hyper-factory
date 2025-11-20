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

# إنشاء/تحديث هيكل قاعدة المعرفة
sqlite3 "$KNOW_DB" "
ATTACH DATABASE '$DB_PATH' AS factory;

-- جدول مواضيع البحث
CREATE TABLE IF NOT EXISTS research_topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    category TEXT,
    importance INTEGER DEFAULT 1,
    tasks_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول قاعدة المعرفة
CREATE TABLE IF NOT EXISTS knowledge_base (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    content TEXT,
    quality_score REAL DEFAULT 0.0,
    source_type TEXT,
    related_tasks_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- تحديث مواضيع البحث من المهام
INSERT OR REPLACE INTO research_topics (topic, category, importance, tasks_count)
SELECT 
    task_type as topic,
    'task_type' as category,
    COUNT(*) as importance,
    COUNT(*) as tasks_count
FROM factory.tasks 
GROUP BY task_type
ORDER BY COUNT(*) DESC;

-- تحديث قاعدة المعرفة من المهام المكتملة
INSERT OR REPLACE INTO knowledge_base (topic, content, quality_score, source_type, related_tasks_count)
SELECT 
    t.task_type as topic,
    'تم جمع معرفة من ' || COUNT(*) || ' مهمة من نوع ' || t.task_type as content,
    (COUNT(*) * 1.0 / (SELECT COUNT(*) FROM factory.tasks WHERE status='done')) as quality_score,
    'task_analysis' as source_type,
    COUNT(*) as related_tasks_count
FROM factory.tasks t
WHERE t.status = 'done'
GROUP BY t.task_type;

-- تحديث وقت التعديل
UPDATE research_topics SET updated_at = CURRENT_TIMESTAMP;
UPDATE knowledge_base SET updated_at = CURRENT_TIMESTAMP;
"

echo "✅ تم تحديث البحث والمعرفة:"
echo "   - مواضيع البحث: $(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM research_topics;")"
echo "   - عناصر المعرفة: $(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM knowledge_base;")"

