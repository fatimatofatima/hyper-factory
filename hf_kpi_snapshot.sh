#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
REPORT_DIR="$ROOT/reports/factory"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$REPORT_DIR/kpi_$TS.txt"

mkdir -p "$REPORT_DIR"

echo "📊 Hyper Factory – KPI Snapshot" | tee "$OUT_FILE"
echo "================================" | tee -a "$OUT_FILE"
echo "⏰ $(date)" | tee -a "$OUT_FILE"
echo "📄 DB: $DB_PATH" | tee -a "$OUT_FILE"
echo "" | tee -a "$OUT_FILE"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ factory.db غير موجود: $DB_PATH" | tee -a "$OUT_FILE"
    exit 1
fi

# 1) ملخص عام للمهام
echo "1) ملخص عام للمهام:"            | tee -a "$OUT_FILE"
echo "--------------------"           | tee -a "$OUT_FILE"

sqlite3 -header -column "$DB_PATH" "
SELECT COUNT(*) AS total_tasks FROM tasks;
" | tee -a "$OUT_FILE"

sqlite3 -header -column "$DB_PATH" "
SELECT status, COUNT(*) AS count
FROM tasks
GROUP BY status
ORDER BY count DESC;
" | tee -a "$OUT_FILE"

sqlite3 -header -column "$DB_PATH" "
SELECT 
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

# 2) توزيع المهام حسب النوع (task_type)
echo "2) توزيع المهام حسب النوع (task_type):" | tee -a "$OUT_FILE"
echo "----------------------------------------" | tee -a "$OUT_FILE"

sqlite3 -header -column "$DB_PATH" "
SELECT task_type, COUNT(*) AS count
FROM tasks
GROUP BY task_type
ORDER BY count DESC;
" 2>>"$OUT_FILE" | tee -a "$OUT_FILE" || {
    echo "⚠️ تعذر قراءة توزيع المهام حسب النوع" | tee -a "$OUT_FILE"
}

echo "" | tee -a "$OUT_FILE"

# 3) أفضل 10 عمال حسب عدد التشغيل
echo "3) أفضل 10 عمال حسب عدد التشغيل:" | tee -a "$OUT_FILE"
echo "----------------------------------" | tee -a "$OUT_FILE"

sqlite3 -header -column "$DB_PATH" "
SELECT 
    id AS agent_id,
    display_name AS name,
    family,
    role,
    level,
    success_rate,
    total_runs
FROM agents
ORDER BY total_runs DESC
LIMIT 10;
" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"

# 4) أسوأ العمال (>=5 runs) حسب النجاح
echo "4) أسوأ 5 عمال (total_runs >= 5) حسب نسبة النجاح:" | tee -a "$OUT_FILE"
echo "--------------------------------------------------" | tee -a "$OUT_FILE"

sqlite3 -header -column "$DB_PATH" "
SELECT 
    id AS agent_id,
    display_name AS name,
    success_rate,
    total_runs
FROM agents
WHERE total_runs >= 5
ORDER BY success_rate ASC, total_runs DESC
LIMIT 5;
" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"

# 5) توزيع التعيينات task_assignments
echo "5) توزيع التعيينات على العمال (task_assignments):" | tee -a "$OUT_FILE"
echo "--------------------------------------------------" | tee -a "$OUT_FILE"

sqlite3 -header -column "$DB_PATH" "
SELECT 
    agent_id,
    COUNT(*) AS assignments
FROM task_assignments
GROUP BY agent_id
ORDER BY assignments DESC;
" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"
echo "✅ تم حفظ تقرير KPI في:" | tee -a "$OUT_FILE"
echo "   $OUT_FILE"            | tee -a "$OUT_FILE"
