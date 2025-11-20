#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
KNOW_DB="$ROOT/data/knowledge/knowledge.db"
REPORT_DIR="$ROOT/reports/hyper_brain"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$REPORT_DIR/hyper_brain_$TS.txt"

mkdir -p "$REPORT_DIR"

echo "🧠 Hyper Factory – Hyper Brain Report" | tee "$OUT_FILE"
echo "======================================" | tee -a "$OUT_FILE"
echo "⏰ $(date)" | tee -a "$OUT_FILE"
echo "📄 FACTORY DB : $DB_PATH" | tee -a "$OUT_FILE"
echo "📄 KNOWLEDGE DB: $KNOW_DB" | tee -a "$OUT_FILE"
echo "" | tee -a "$OUT_FILE"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ factory.db غير موجود: $DB_PATH" | tee -a "$OUT_FILE"
    exit 1
fi

mkdir -p "$(dirname "$KNOW_DB")"

# ضمان وجود جداول المعرفة الأساسية
sqlite3 "$KNOW_DB" "
CREATE TABLE IF NOT EXISTS training_recommendations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT,
    display_name TEXT,
    current_success REAL,
    total_runs INTEGER,
    recommended_focus TEXT,
    recommendation_type TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS performance_evaluations (
    evaluation_id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT,
    evaluation_type TEXT,
    score INTEGER,
    feedback TEXT,
    recommendations TEXT,
    evaluated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

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

CREATE TABLE IF NOT EXISTS knowledge_base (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    content TEXT,
    source_type TEXT,
    quality_score INTEGER DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    last_updated TEXT DEFAULT CURRENT_TIMESTAMP
);
"

########################################
# 1) ملخص حالة المصنع (factory.db)
########################################
echo "1) حالة المصنع – المهام والعمال" | tee -a "$OUT_FILE"
echo "--------------------------------" | tee -a "$OUT_FILE"

sqlite3 -header -column "$DB_PATH" "
SELECT 
    COUNT(*) AS total_tasks,
    SUM(CASE WHEN status = 'done'   THEN 1 ELSE 0 END) AS done,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed,
    SUM(CASE WHEN status IN ('queued','assigned') THEN 1 ELSE 0 END) AS backlog,
    ROUND(
        100.0 * SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END) 
        / NULLIF(COUNT(*),0),
        2
    ) AS success_rate_percent
FROM tasks;
" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"
echo "🔹 توزيع المهام حسب النوع (task_type):" | tee -a "$OUT_FILE"

sqlite3 -header -column "$DB_PATH" "
SELECT task_type, COUNT(*) AS count
FROM tasks
GROUP BY task_type
ORDER BY count DESC;
" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"
echo "🔹 أفضل 5 عمال حسب التشغيل:" | tee -a "$OUT_FILE"

sqlite3 -header -column "$DB_PATH" "
SELECT 
    id AS agent_id,
    display_name,
    family,
    level,
    success_rate,
    total_runs
FROM agents
ORDER BY total_runs DESC
LIMIT 5;
" | tee -a "$OUT_FILE"

########################################
# 2) حالة التدريب والتوصيات (knowledge.db)
########################################
echo "" | tee -a "$OUT_FILE"
echo "2) حالة التدريب والتوصيات" | tee -a "$OUT_FILE"
echo "--------------------------" | tee -a "$OUT_FILE"

sqlite3 -header -column "$KNOW_DB" "
SELECT 
    COUNT(*) AS total_recommendations
FROM training_recommendations;
" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"
echo "🔹 أهم 5 توصيات تدريبية (أحدثها):" | tee -a "$OUT_FILE"

sqlite3 -header -column "$KNOW_DB" "
SELECT 
    agent_id,
    display_name,
    ROUND(current_success,2) AS current_success,
    total_runs,
    substr(recommended_focus,1,60) AS focus,
    recommendation_type,
    created_at
FROM training_recommendations
ORDER BY created_at DESC
LIMIT 5;
" | tee -a "$OUT_FILE"

########################################
# 3) حالة التقييم الذاتي (Performance Evaluations)
########################################
echo "" | tee -a "$OUT_FILE"
echo "3) حالة التقييم الذاتي للأداء" | tee -a "$OUT_FILE"
echo "------------------------------" | tee -a "$OUT_FILE"

sqlite3 -header -column "$KNOW_DB" "
SELECT COUNT(*) AS total_evaluations
FROM performance_evaluations;
" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"
echo "🔹 عينة من آخر 5 تقييمات:" | tee -a "$OUT_FILE"

sqlite3 -header -column "$KNOW_DB" "
SELECT 
    agent_id,
    evaluation_type,
    score,
    substr(feedback,1,60) AS feedback,
    substr(recommendations,1,60) AS recommendations,
    evaluated_at
FROM performance_evaluations
ORDER BY evaluated_at DESC
LIMIT 5;
" | tee -a "$OUT_FILE"

########################################
# 4) حالة المعرفة ومواضيع البحث
########################################
echo "" | tee -a "$OUT_FILE"
echo "4) حالة المعرفة ومواضيع البحث" | tee -a "$OUT_FILE"
echo "------------------------------" | tee -a "$OUT_FILE"

sqlite3 -header -column "$KNOW_DB" "
SELECT 
    COUNT(*) AS topics_count,
    SUM(CASE WHEN importance = 'critical' THEN 1 ELSE 0 END) AS critical_topics,
    SUM(CASE WHEN importance = 'high'     THEN 1 ELSE 0 END) AS high_topics
FROM research_topics;
" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"
echo "🔹 أهم مواضيع البحث (TOP 5 بالمهام):" | tee -a "$OUT_FILE"

sqlite3 -header -column "$KNOW_DB" "
SELECT 
    topic,
    importance,
    tasks_count,
    last_seen
FROM research_topics
ORDER BY 
    CASE importance 
        WHEN 'critical' THEN 1
        WHEN 'high'     THEN 2
        ELSE 3
    END,
    tasks_count DESC
LIMIT 5;
" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"
echo "🔹 إحصائية عامة عن جدول knowledge_base:" | tee -a "$OUT_FILE"

sqlite3 -header -column "$KNOW_DB" "
SELECT 
    COUNT(*) AS knowledge_items,
    ROUND(AVG(quality_score),2) AS avg_quality
FROM knowledge_base;
" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"
echo "✅ Hyper Brain Report مكتمل" | tee -a "$OUT_FILE"
echo "📁 التقرير: $OUT_FILE"       | tee -a "$OUT_FILE"
