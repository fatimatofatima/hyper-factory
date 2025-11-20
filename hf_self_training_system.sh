#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
KNOW_DB="$ROOT/data/knowledge/knowledge.db"

echo "🎓 Hyper Factory – Self Training System"
echo "========================================"
echo "⏰ $(date)"
echo "📄 FACTORY DB : $DB_PATH"
echo "📄 KNOWLEDGE DB: $KNOW_DB"
echo ""

if [ ! -f "$DB_PATH" ]; then
    echo "❌ factory.db غير موجود: $DB_PATH"
    exit 1
fi

mkdir -p "$(dirname "$KNOW_DB")"

echo "📌 توليد توصيات تدريبية بناءً على أداء العمال..."

# تحديث هيكل جدول training_recommendations إذا لزم الأمر
sqlite3 "$KNOW_DB" "
CREATE TABLE IF NOT EXISTS training_recommendations (
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
"

# تحديث توصيات التدريب من أداء العمال
sqlite3 "$KNOW_DB" "
ATTACH DATABASE '$DB_PATH' AS factory;

DELETE FROM training_recommendations;

INSERT INTO training_recommendations (agent_id, display_name, current_success, total_runs, recommended_focus, priority)
SELECT 
    a.id as agent_id,
    a.display_name,
    a.success_rate as current_success,
    a.total_runs,
    CASE 
        WHEN a.total_runs = 0 THEN 'بدء التشغيل الأول للمهام البسيطة'
        WHEN a.success_rate < 80 THEN 'تحسين نسبة النجاح عبر المهام التدريبية'
        WHEN a.total_runs < 5 THEN 'زيادة عدد المهام لاكتساب الخبرة'
        WHEN a.success_rate >= 95 THEN 'الحفاظ على الأداء المتميز'
        ELSE 'تحسين الكفاءة العامة'
    END as recommended_focus,
    CASE 
        WHEN a.total_runs = 0 THEN 1
        WHEN a.success_rate < 80 THEN 1
        ELSE 2
    END as priority
FROM factory.agents a
WHERE a.id IS NOT NULL;
"

echo "✅ Self Training System اكتمل (تم توليد $(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM training_recommendations;") توصية تدريبية)"
