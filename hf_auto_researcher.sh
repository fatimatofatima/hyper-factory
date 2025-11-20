#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
KNOWLEDGE_DB="$ROOT/data/knowledge/knowledge.db"

echo "🔍 Hyper Factory – Auto Researcher"
echo "==================================="
echo "⏰ $(date)"

# إنشاء قاعدة معرفة إذا لم تكن موجودة
mkdir -p "$(dirname "$KNOWLEDGE_DB")"
sqlite3 "$KNOWLEDGE_DB" "
CREATE TABLE IF NOT EXISTS knowledge_base (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    content TEXT,
    source_type TEXT,
    quality_score INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS research_topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    priority TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"

# 1. اكتشاف مواضيع بحث جديدة من أنماط الأداء
echo "1. 🎯 اكتشاف مواضيع بحث جديدة..."
sqlite3 "$DB_PATH" "
-- استخراج مواضيع بحث من أنماط النجاح والفشل
INSERT INTO research_topics (topic, priority)
SELECT 
    'أفضل ممارسات ' || task_type || ' للعامل ' || agent_id,
    'high'
FROM (
    SELECT 
        ta.agent_id,
        t.task_type,
        COUNT(*) as success_count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM task_assignments WHERE agent_id = ta.agent_id), 2) as success_rate
    FROM task_assignments ta
    JOIN tasks t ON ta.task_id = t.id
    WHERE ta.result_status = 'success'
    AND ta.completed_at > datetime('now', '-24 hours')
    GROUP BY ta.agent_id, t.task_type
    HAVING success_count >= 3 AND success_rate > 80
    LIMIT 3
)
WHERE NOT EXISTS (
    SELECT 1 FROM research_topics 
    WHERE topic LIKE '%' || task_type || '%' 
    AND topic LIKE '%' || agent_id || '%'
    AND created_at > datetime('now', '-7 days')
);

-- مواضيع بحث من نقاط الضعف
INSERT INTO research_topics (topic, priority)
SELECT 
    'تحسين ' || task_type || ' للعامل ' || agent_id,
    'critical'
FROM (
    SELECT 
        ta.agent_id,
        t.task_type,
        COUNT(*) as fail_count
    FROM task_assignments ta
    JOIN tasks t ON ta.task_id = t.id
    WHERE ta.result_status = 'fail'
    AND ta.completed_at > datetime('now', '-12 hours')
    GROUP BY ta.agent_id, t.task_type
    HAVING fail_count >= 2
    LIMIT 3
)
WHERE NOT EXISTS (
    SELECT 1 FROM research_topics 
    WHERE topic LIKE '%' || task_type || '%' 
    AND topic LIKE '%' || agent_id || '%'
    AND created_at > datetime('now', '-3 days')
);

SELECT '✅ تم اكتشاف ' || changes() || ' موضوع بحث جديد' AS result;
"

# 2. إنشاء مهام بحث تلقائية
echo "2. 📚 إنشاء مهام البحث التلقائية..."
sqlite3 "$DB_PATH" "
INSERT INTO tasks (created_at, source, description, task_type, priority, status)
SELECT 
    CURRENT_TIMESTAMP,
    'auto_researcher',
    'بحث تلقائي: ' || rt.topic,
    'knowledge',
    CASE rt.priority 
        WHEN 'critical' THEN 'high'
        WHEN 'high' THEN 'high' 
        ELSE 'normal'
    END,
    'queued'
FROM research_topics rt
WHERE rt.status = 'pending'
AND NOT EXISTS (
    SELECT 1 FROM tasks 
    WHERE description LIKE '%' || rt.topic || '%'
    AND created_at > datetime('now', '-1 day')
)
LIMIT 5;

-- تحديث حالة مواضيع البحث
UPDATE research_topics 
SET status = 'researching' 
WHERE topic IN (
    SELECT REPLACE(REPLACE(description, 'بحث تلقائي: ', ''), 'بحث متقدم: ', '')
    FROM tasks 
    WHERE source = 'auto_researcher' 
    AND status IN ('queued', 'assigned')
);

SELECT '✅ تم إنشاء ' || changes() || ' مهمة بحث تلقائي' AS result;
"

# 3. محاكاة جمع المعرفة من "الإنترنت"
echo "3. 🌐 محاكاة جمع المعرفة الذكي..."
RESEARCH_TOPICS=$(sqlite3 "$DB_PATH" "
SELECT DISTINCT 
    CASE 
        WHEN description LIKE '%debug%' OR description LIKE '%تصحيح%' THEN 'تقنيات تصحيح الأخطاء'
        WHEN description LIKE '%architecture%' OR description LIKE '%معماري%' THEN 'هندسة الأنظمة'
        WHEN description LIKE '%coaching%' OR description LIKE '%تدريب%' THEN 'أساليب التدريب'
        WHEN description LIKE '%knowledge%' OR description LIKE '%معرفة%' THEN 'إدارة المعرفة'
        WHEN description LIKE '%quality%' OR description LIKE '%جودة%' THEN 'مراقبة الجودة'
        ELSE 'مهارات تقنية عامة'
    END as knowledge_area
FROM tasks 
WHERE source = 'auto_researcher' 
AND status IN ('queued', 'assigned')
LIMIT 3
")

for topic in $RESEARCH_TOPICS; do
    echo "🔍 جمع معرفة عن: $topic"
    
    # محاكاة البحث وجمع المعلومات
    sqlite3 "$KNOWLEDGE_DB" "
    INSERT INTO knowledge_base (topic, content, source_type, quality_score)
    VALUES (
        '$topic',
        'معرفة متراكمة حول $topic تم جمعها تلقائياً من خلال تحليل أنماط الأداء وتحسين العمليات. تشمل أفضل الممارسات والدروس المستفادة وأساليب التحسين المستمر.',
        'auto_research',
        85
    )
    ON CONFLICT(topic) DO UPDATE SET
        content = excluded.content,
        last_updated = CURRENT_TIMESTAMP,
        quality_score = excluded.quality_score;
    "
done

echo "📊 إحصائيات البحث الذاتي:"
sqlite3 "$DB_PATH" "
SELECT '🎯 مواضيع البحث: ' || COUNT(*) || ' موضوع' FROM research_topics;
SELECT '🔍 قيد البحث: ' || COUNT(*) || ' موضوع' FROM research_topics WHERE status = 'researching';
SELECT '📚 مهام البحث: ' || COUNT(*) || ' مهمة' FROM tasks WHERE source = 'auto_researcher';
"

sqlite3 "$KNOWLEDGE_DB" "
SELECT '🧠 المعرفة المتراكمة: ' || COUNT(*) || ' موضوع' FROM knowledge_base;
SELECT '⭐ جودة المعرفة: ' || ROUND(AVG(quality_score), 1) || '%' FROM knowledge_base;
"

echo "✅ Auto Researcher اكتمل"
