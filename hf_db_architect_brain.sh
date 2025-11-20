#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
LOG_DIR="$ROOT/reports/db_architect"
TS="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$LOG_DIR/db_architect_report_$TS.txt"

mkdir -p "$LOG_DIR"

echo "🧠 Hyper Factory – DB Architect Brain" | tee "$OUT_FILE"
echo "======================================" | tee -a "$OUT_FILE"
echo "⏰ $(date)" | tee -a "$OUT_FILE"
echo "📄 DB: $DB_PATH" | tee -a "$OUT_FILE"
echo "" | tee -a "$OUT_FILE"

if [ ! -f "$DB_PATH" ]; then
    echo "❌ قاعدة البيانات غير موجودة: $DB_PATH" | tee -a "$OUT_FILE"
    exit 1
fi

echo "🔎 PRAGMA integrity_check:" | tee -a "$OUT_FILE"
sqlite3 "$DB_PATH" "PRAGMA integrity_check;" | tee -a "$OUT_FILE"
echo "" | tee -a "$OUT_FILE"

echo "📋 الجداول الموجودة:" | tee -a "$OUT_FILE"
sqlite3 "$DB_PATH" ".tables" | sed 's/^/  - /' | tee -a "$OUT_FILE"
echo "" | tee -a "$OUT_FILE"

CORE_TABLES=(
  agents
  tasks
  task_assignments
  skills
  tracks
  track_phases
  user_skills
  user_tracks
  learning_log
  system_settings
  daily_reports
)

echo "📊 فحص هيكل الجداول الأساسية وحجمها:" | tee -a "$OUT_FILE"
for T in "${CORE_TABLES[@]}"; do
    echo "" | tee -a "$OUT_FILE"
    echo "-----------------------------" | tee -a "$OUT_FILE"
    echo "📌 Table: $T" | tee -a "$OUT_FILE"

    EXISTS=$(sqlite3 "$DB_PATH" "
        SELECT COUNT(*) 
        FROM sqlite_master 
        WHERE type='table' AND name='$T';
    ")
    if [ "$EXISTS" != "1" ]; then
        echo "  ⚠️ الجدول غير موجود" | tee -a "$OUT_FILE"
        continue
    fi

    echo "  ▸ الهيكل:" | tee -a "$OUT_FILE"
    sqlite3 "$DB_PATH" "PRAGMA table_info($T);" | sed 's/^/    /' | tee -a "$OUT_FILE"

    echo "  ▸ عدد السجلات:" | tee -a "$OUT_FILE"
    sqlite3 "$DB_PATH" "SELECT COUNT(*) AS row_count FROM $T;" | sed 's/^/    /' | tee -a "$OUT_FILE"
done

echo "" | tee -a "$OUT_FILE"
echo "📈 لمحة سريعة عن أداء العمال (agents):" | tee -a "$OUT_FILE"
sqlite3 "$DB_PATH" -header -column "
SELECT
    id,
    display_name,
    family,
    level,
    success_rate,
    total_runs
FROM agents
ORDER BY priority_weight DESC, success_rate DESC, total_runs DESC;
" 2>>"$OUT_FILE" | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"
echo "📌 ملخص تحليلي مبدئي (للاستخدام البشري):" | tee -a "$OUT_FILE"
echo "- هذا التقرير يمثل لقطة بنيوية لقاعدة البيانات في هذا التوقيت." | tee -a "$OUT_FILE"
echo "- يمكن استخدامه لبناء قرارات: فهارس، تحسين جداول، تقسيم مسئوليات العمال." | tee -a "$OUT_FILE"
echo "- عامل db_architect مسؤول عن مراجعة هذه التقارير واقتراح تحسينات." | tee -a "$OUT_FILE"

echo "" | tee -a "$OUT_FILE"
echo "✅ DB Architect Brain run finished. Report:" | tee -a "$OUT_FILE"
echo "   $OUT_FILE" | tee -a "$OUT_FILE"
