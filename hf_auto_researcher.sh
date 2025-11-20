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

# 0) تأكد من وجود قاعدة المصنع
if [ ! -f "$DB_PATH" ]; then
    echo "❌ factory.db غير موجود: $DB_PATH"
    exit 1
fi

# 1) تأكد من مسار قاعدة المعرفة
mkdir -p "$ROOT/data/knowledge"

echo "🧠 بناء جداول المعرفة وتحديثها..."
sqlite3 "$KNOW_DB" "
ATTACH DATABASE '$DB_PATH' AS factory;

-- جدول مواضيع البحث
CREATE TABLE IF NOT EXISTS research_topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    source_type TEXT,
    priority TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول لقطات المؤشرات
CREATE TABLE IF NOT EXISTS knowledge_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    snapshot_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metric TEXT NOT NULL,
    value REAL,
    details TEXT
);

-- لقطة عامة عن المهام
INSERT INTO knowledge_snapshots (metric, value, details)
VALUES
  ('tasks_total', (SELECT COUNT(*) FROM factory.tasks), 'إجمالي عدد المهام'),
  ('tasks_done',  (SELECT COUNT(*) FROM factory.tasks WHERE status = ''done''), 'عدد المهام المنتهية'),
  ('tasks_failed',(SELECT COUNT(*) FROM factory.tasks WHERE status = ''failed''), 'عدد المهام الفاشلة');

-- تسجيل مواضيع بحث لكل نوع مهمة
INSERT INTO research_topics (topic, source_type, priority)
SELECT
  'تحسين مهام النوع: ' || COALESCE(t.type, 'غير معروف') AS topic,
  'tasks_stats' AS source_type,
  CASE 
    WHEN SUM(CASE WHEN t.status = 'failed' THEN 1 ELSE 0 END) > 0 THEN 'high'
    ELSE 'normal'
  END AS priority
FROM factory.tasks t
GROUP BY t.type;

DETACH DATABASE factory;
"

echo ""
echo "✅ Auto Researcher اكتمل (تم تحديث knowledge.db)"
