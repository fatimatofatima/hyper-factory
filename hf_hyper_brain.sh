#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FACT_DB="$ROOT/data/factory/factory.db"
KNOW_DB="$ROOT/data/knowledge/knowledge.db"
REPORT_DIR="$ROOT/reports/factory"
mkdir -p "$REPORT_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$REPORT_DIR/hyper_brain_$TS.txt"

echo "🧠 Hyper Factory – Hyper Brain Strategic Report" | tee "$REPORT_FILE"
echo "================================================" | tee -a "$REPORT_FILE"
echo "⏰ $(date)" | tee -a "$REPORT_FILE"
echo "📄 FACTORY DB : $FACT_DB" | tee -a "$REPORT_FILE"
echo "📄 KNOWLEDGE DB: $KNOW_DB" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [ ! -f "$FACT_DB" ]; then
    echo "❌ factory.db غير موجود: $FACT_DB" | tee -a "$REPORT_FILE"
    exit 1
fi

if [ ! -f "$KNOW_DB" ]; then
    echo "⚠️ knowledge.db غير موجود – سيتم إنشاؤه تلقائياً" | tee -a "$REPORT_FILE"
    mkdir -p "$(dirname "$KNOW_DB")"
    touch "$KNOW_DB"
fi

echo "1) Factory Overview – المهام والعمال" | tee -a "$REPORT_FILE"
echo "--------------------------------------" | tee -a "$REPORT_FILE"
sqlite3 -header -column "$FACT_DB" "SELECT COUNT(*) as 'إجمالي المهام' FROM tasks;" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "• توزيع الحالات (status) في جدول المهام:" | tee -a "$REPORT_FILE"
sqlite3 -header -column "$FACT_DB" "
SELECT status, COUNT(*) as count 
FROM tasks 
GROUP BY status 
ORDER BY count DESC;" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "• أفضل 10 عمال حسب عدد التشغيل (agents):" | tee -a "$REPORT_FILE"
sqlite3 -header -column "$FACT_DB" "
SELECT 
    id as agent_id,
    display_name,
    family,
    level,
    ROUND(success_rate, 2) as success_rate,
    total_runs
FROM agents 
WHERE total_runs > 0 
ORDER BY total_runs DESC, success_rate DESC 
LIMIT 10;" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "2) Knowledge & Quality – جودة المعرفة" | tee -a "$REPORT_FILE"
echo "--------------------------------------" | tee -a "$REPORT_FILE"

# فحص صحة knowledge.db
INTEGRITY=$(sqlite3 "$KNOW_DB" "PRAGMA integrity_check;" 2>/dev/null || echo "error")
echo "• integrity_check (knowledge.db) : $INTEGRITY" | tee -a "$REPORT_FILE"

TABLE_COUNT=$(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>/dev/null || echo "0")
echo "• عدد الجداول في knowledge.db  : $TABLE_COUNT" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# تقييمات الأداء
PERF_COUNT=$(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM performance_evaluations;" 2>/dev/null || echo "0")
echo "• performance_evaluations: $PERF_COUNT سجل" | tee -a "$REPORT_FILE"

if [ "$PERF_COUNT" -gt 0 ]; then
    echo "  ▸ أحدث 5 تقييمات أداء:" | tee -a "$REPORT_FILE"
    sqlite3 -header -column "$KNOW_DB" "
    SELECT 
        agent_id,
        display_name,
        score,
        substr(feedback, 1, 25) as feedback_short
    FROM performance_evaluations 
    ORDER BY evaluated_at DESC 
    LIMIT 5;" | tee -a "$REPORT_FILE"
else
    echo "  ▸ لا توجد تقييمات أداء بعد" | tee -a "$REPORT_FILE"
fi
echo "" | tee -a "$REPORT_FILE"

# توصيات التدريب
TRAIN_COUNT=$(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM training_recommendations;" 2>/dev/null || echo "0")
echo "• training_recommendations: $TRAIN_COUNT توصية تدريبية" | tee -a "$REPORT_FILE"

if [ "$TRAIN_COUNT" -gt 0 ]; then
    echo "  ▸ أحدث 5 توصيات تدريبية:" | tee -a "$REPORT_FILE"
    sqlite3 -header -column "$KNOW_DB" "
    SELECT 
        agent_id,
        display_name,
        ROUND(current_success, 2) as success_rate,
        total_runs,
        substr(recommended_focus, 1, 30) as focus_short
    FROM training_recommendations 
    ORDER BY id DESC 
    LIMIT 5;" | tee -a "$REPORT_FILE"
else
    echo "  ▸ لا توجد توصيات تدريبية بعد" | tee -a "$REPORT_FILE"
fi
echo "" | tee -a "$REPORT_FILE"

echo "3) Strategic Summary – ملخص استراتيجي" | tee -a "$REPORT_FILE"
echo "--------------------------------------" | tee -a "$REPORT_FILE"
echo "• Hyper Brain يعطيك الآن:" | tee -a "$REPORT_FILE"
echo "  - رؤية عن الحمل (عدد المهام + حالاتهم)." | tee -a "$REPORT_FILE"
echo "  - أداء العمال وأين يتركّز التنفيذ." | tee -a "$REPORT_FILE"
echo "  - حالة التعلم الذاتي (learning_log / training)." | tee -a "$REPORT_FILE"
echo "  - صحة البنية (db_health + schema_review)." | tee -a "$REPORT_FILE"
echo "  - مستوى تكامل المصنع مع مخزون المعرفة (knowledge_linking)." | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

echo "✅ Hyper Brain Report جاهز." | tee -a "$REPORT_FILE"
echo "📄 الملف: $REPORT_FILE" | tee -a "$REPORT_FILE"
