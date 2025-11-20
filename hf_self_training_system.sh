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

mkdir -p "$ROOT/data/knowledge"

echo "📌 توليد توصيات تدريبية بناءً على أداء العمال..."
sqlite3 "$KNOW_DB" "
ATTACH DATABASE '$DB_PATH' AS factory;

-- جدول توصيات التدريب
CREATE TABLE IF NOT EXISTS training_recommendations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT,
    display_name TEXT,
    current_success REAL,
    total_runs INTEGER,
    recommended_focus TEXT,
    reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- إنشاء توصيات للعمال ذوي الأداء الأقل من 80% مع وجود تشغيل فعلي
INSERT INTO training_recommendations (
    agent_id,
    display_name,
    current_success,
    total_runs,
    recommended_focus,
    reason
)
SELECT
    a.id,
    a.display_name,
    a.success_rate,
    a.total_runs,
    CASE
        WHEN a.success_rate < 50 THEN 'خطة تدريب مكثفة + مهام debug/quality'
        ELSE 'خطة تحسين متدرجة + مهام coaching/quality'
    END AS recommended_focus,
    'success_rate=' || printf('%.2f', a.success_rate) || ', runs=' || a.total_runs
FROM factory.agents a
WHERE a.total_runs >= 3
  AND a.success_rate < 80;

DETACH DATABASE factory;
"

echo ""
echo "✅ Self Training System اكتمل (تم توليد توصيات تدريبية في training_recommendations)"
