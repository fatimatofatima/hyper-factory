#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
KNOW_DB="$ROOT/data/knowledge/knowledge.db"

echo "📊 Hyper Factory – Self Evaluation System"
echo "=========================================="
echo "⏰ $(date)"
echo "📄 FACTORY DB : $DB_PATH"
echo "📄 KNOWLEDGE DB: $KNOW_DB"
echo ""

if [ ! -f "$DB_PATH" ]; then
    echo "❌ factory.db غير موجود: $DB_PATH"
    exit 1
fi

mkdir -p "$ROOT/data/knowledge"

echo "🧮 تقييم أداء العمال وتخزينه في knowledge.db..."
sqlite3 "$KNOW_DB" "
ATTACH DATABASE '$DB_PATH' AS factory;

-- جدول التقييمات
CREATE TABLE IF NOT EXISTS performance_evaluations (
    evaluation_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT,
    evaluation_type TEXT,
    score INTEGER,
    feedback TEXT,
    recommendations TEXT,
    evaluated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- إدخال تقييم جديد لكل عامل (لا حذف للتقييمات القديمة)
INSERT INTO performance_evaluations (
    agent_id,
    evaluation_type,
    score,
    feedback,
    recommendations
)
SELECT
    a.id AS agent_id,
    'auto_snapshot' AS evaluation_type,
    CAST(ROUND(a.success_rate, 0) AS INTEGER) AS score,
    CASE
        WHEN a.total_runs = 0 THEN 'لا توجد بيانات كافية عن هذا العامل بعد.'
        WHEN a.success_rate >= 80 THEN 'أداء ممتاز ومستقر.'
        WHEN a.success_rate >= 50 THEN 'أداء متوسط يحتاج إلى تحسين في بعض الجوانب.'
        ELSE 'أداء ضعيف – يحتاج إلى مراجعة وتدريب مكثف.'
    END AS feedback,
    CASE
        WHEN a.total_runs = 0 THEN 'تعيين مهام بسيطة لبدء قياس الأداء ثم تصميم خطة تدريب.'
        WHEN a.success_rate >= 80 THEN 'الحفاظ على مستوى العمل الحالي مع مراقبة دورية.'
        WHEN a.success_rate >= 50 THEN 'إنشاء مهام quality/debug إضافية لهذا العامل مع خطة تدريبية.'
        ELSE 'تخفيض أولوية المهام الحرجة لهذا العامل وزيادة مهام التدريب/coaching.'
    END AS recommendations
FROM factory.agents a;

DETACH DATABASE factory;
"

echo ""
echo "✅ Self Evaluation اكتمل (تم تخزين تقييمات في performance_evaluations)"
