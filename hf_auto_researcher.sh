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

# إعادة بناء هيكل قاعدة المعرفة بالكامل
sqlite3 "$KNOW_DB" "
-- حذف الجداول القديمة إذا كانت بها مشاكل
DROP TABLE IF EXISTS research_topics;
DROP TABLE IF EXISTS knowledge_base;
DROP TABLE IF EXISTS training_recommendations;
DROP TABLE IF EXISTS performance_evaluations;
DROP TABLE IF EXISTS db_health_reports;
DROP TABLE IF EXISTS schema_review_reports;
DROP TABLE IF EXISTS knowledge_linking_reports;

-- جدول مواضيع البحث (مُصلح)
CREATE TABLE research_topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    category TEXT,
    importance INTEGER DEFAULT 1,
    tasks_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول قاعدة المعرفة
CREATE TABLE knowledge_base (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    content TEXT,
    quality_score REAL DEFAULT 0.0,
    source_type TEXT,
    related_tasks_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- توصيات التدريب (مُصلح)
CREATE TABLE training_recommendations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    display_name TEXT,
    current_success REAL DEFAULT 0.0,
    total_runs INTEGER DEFAULT 0,
    recommended_focus TEXT,
    recommendation_type TEXT DEFAULT 'skill_improvement',
    priority INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- تقييمات الأداء (مُصلح)
CREATE TABLE performance_evaluations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    display_name TEXT,
    evaluation_type TEXT DEFAULT 'auto_snapshot',
    score INTEGER DEFAULT 0,
    feedback TEXT,
    recommendations TEXT,
    evaluated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- تقارير صحة قاعدة البيانات
CREATE TABLE db_health_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    integrity_status TEXT,
    tables_count INTEGER,
    report_file TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- تقارير مراجعة الهيكل
CREATE TABLE schema_review_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tables_reviewed INTEGER,
    issues_found INTEGER,
    recommendations TEXT,
    report_file TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- تقارير ربط المعرفة
CREATE TABLE knowledge_linking_reports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    links_created INTEGER,
    knowledge_items INTEGER,
    report_file TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"

# تحديث البيانات من factory.db
sqlite3 "$KNOW_DB" "
ATTACH DATABASE '$DB_PATH' AS factory;

-- تحديث مواضيع البحث من المهام
INSERT INTO research_topics (topic, category, importance, tasks_count)
SELECT 
    task_type as topic,
    'task_type' as category,
    COUNT(*) as importance,
    COUNT(*) as tasks_count
FROM factory.tasks 
GROUP BY task_type
ORDER BY COUNT(*) DESC;

-- تحديث قاعدة المعرفة من المهام المكتملة
INSERT INTO knowledge_base (topic, content, quality_score, source_type, related_tasks_count)
SELECT 
    t.task_type as topic,
    'تم جمع معرفة من ' || COUNT(*) || ' مهمة من نوع ' || t.task_type as content,
    (COUNT(*) * 1.0 / (SELECT COUNT(*) FROM factory.tasks WHERE status='done')) as quality_score,
    'task_analysis' as source_type,
    COUNT(*) as related_tasks_count
FROM factory.tasks t
WHERE t.status = 'done'
GROUP BY t.task_type;

-- تحديث توصيات التدريب من العمال
INSERT INTO training_recommendations (agent_id, display_name, current_success, total_runs, recommended_focus)
SELECT 
    a.id as agent_id,
    a.display_name,
    a.success_rate as current_success,
    a.total_runs,
    CASE 
        WHEN a.total_runs = 0 THEN 'بدء التشغيل الأول'
        WHEN a.success_rate < 80 THEN 'تحسين نسبة النجاح'
        WHEN a.total_runs < 5 THEN 'زيادة عدد المهام'
        ELSE 'الحفاظ على الأداء الحالي'
    END as recommended_focus
FROM factory.agents a
WHERE a.total_runs > 0;

-- تحديث تقييمات الأداء
INSERT INTO performance_evaluations (agent_id, display_name, score, feedback, recommendations)
SELECT 
    a.id as agent_id,
    a.display_name,
    CASE 
        WHEN a.success_rate >= 95 THEN 100
        WHEN a.success_rate >= 80 THEN 90
        WHEN a.success_rate >= 60 THEN 75
        ELSE 50
    END as score,
    CASE 
        WHEN a.success_rate >= 95 THEN 'أداء ممتاز ومستقر.'
        WHEN a.success_rate >= 80 THEN 'أداء جيد مع مجال للتحسين.'
        WHEN a.success_rate >= 60 THEN 'أداء مقبول يحتاج مراقبة.'
        ELSE 'أداء يحتاج تحسين عاجل.'
    END as feedback,
    CASE 
        WHEN a.total_runs = 0 THEN 'بدء التشغيل الأول للمهام البسيطة'
        WHEN a.success_rate < 80 THEN 'تحسين نسبة النجاح عبر المهام التدريبية'
        ELSE 'الحفاظ على مستوى العمل الحالي مع مراقبة دورية'
    END as recommendations
FROM factory.agents a;

-- تحديث وقت التعديل
UPDATE research_topics SET updated_at = CURRENT_TIMESTAMP;
UPDATE knowledge_base SET updated_at = CURRENT_TIMESTAMP;
"

echo "✅ تم تحديث البحث والمعرفة:"
echo "   - مواضيع البحث: $(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM research_topics;")"
echo "   - عناصر المعرفة: $(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM knowledge_base;")"
echo "   - توصيات التدريب: $(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM training_recommendations;")"
echo "   - تقييمات الأداء: $(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM performance_evaluations;")"

