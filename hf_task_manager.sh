#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FACT_DB="$ROOT/data/factory/factory.db"
REPORT_DIR="$ROOT/reports/analyzer"
mkdir -p "$REPORT_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$REPORT_DIR/smart_analysis_$TS.txt"

log() { echo "$@" | tee -a "$REPORT_FILE"; }

echo "🧠 Hyper Factory – Smart Analyzer & Executor" | tee "$REPORT_FILE"
echo "============================================" | tee -a "$REPORT_FILE"
echo "⏰ $(date)" | tee -a "$REPORT_FILE"
echo "📄 FACTORY DB: $FACT_DB" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [ ! -f "$FACT_DB" ]; then
  log "❌ factory.db غير موجود"
  exit 1
fi

if ! command -v sqlite3 >/dev/null 2>&1; then
  log "❌ sqlite3 غير مثبت"
  exit 1
fi

log "📊 [1/4] فحص سلامة القاعدة والجداول..."
INTEGRITY=$(sqlite3 "$FACT_DB" "PRAGMA integrity_check;" || echo "error")
log "   • integrity_check = $INTEGRITY"

TABLES=$(sqlite3 "$FACT_DB" ".tables" || echo "")
MISSING=0
for t in agents tasks task_assignments; do
  if ! echo "$TABLES" | grep -qw "$t"; then
    log "❌ الجدول الأساسي مفقود: $t"
    MISSING=1
  fi
done
if [ "$MISSING" -ne 0 ]; then
  log "⛔ لن يتم تنفيذ أي إصلاحات بسبب نقص الجداول."
  exit 1
fi

log ""
log "📈 [2/4] تحليل العمال والمهام..."

log "## العمال غير النشطين (total_runs = 0)"
sqlite3 "$FACT_DB" -cmd ".headers on" -cmd ".mode column" \
  "SELECT id, display_name, family, level, success_rate, total_runs
   FROM agents
   WHERE total_runs = 0
   ORDER BY id;" | tee -a "$REPORT_FILE"

log ""
log "## توزيع المهام حسب النوع والحالة"
sqlite3 "$FACT_DB" -cmd ".headers on" -cmd ".mode column" \
  "SELECT task_type, status, COUNT(*) AS count
   FROM tasks
   GROUP BY task_type, status
   ORDER BY count DESC;" | tee -a "$REPORT_FILE"

log ""
log "🔧 [3/4] تنفيذ الإصلاحات التلقائية..."

INACTIVE_AGENTS=$(sqlite3 "$FACT_DB" "SELECT id FROM agents WHERE total_runs = 0;")
CREATED_TRAINING=0
if [ -n "$INACTIVE_AGENTS" ]; then
  log "🎯 إنشاء مهام تدريبية للعمال غير النشطين..."
  while IFS= read -r AGENT_ID; do
    [ -z "$AGENT_ID" ] && continue
    TASK_ID=$(sqlite3 "$FACT_DB" "
      INSERT INTO tasks (created_at, source, description, task_type, priority, status)
      VALUES (datetime('now'),
              'system:training_manager',
              'Auto-training task for agent $AGENT_ID',
              'coaching', 'normal', 'queued');
      SELECT last_insert_rowid();
    ")
    sqlite3 "$FACT_DB" "
      INSERT INTO task_assignments
        (task_id, agent_id, decision_reason, assigned_at, completed_at, result_status, result_notes)
      VALUES
        ($TASK_ID, '$AGENT_ID', 'auto-training', datetime('now'), NULL, '', '');
    "
    CREATED_TRAINING=$((CREATED_TRAINING+1))
  done <<< "$INACTIVE_AGENTS"
  log "   • تم إنشاء $CREATED_TRAINING مهمة تدريبية."
else
  log "   • لا يوجد عمال غير نشطين."
fi

log ""
log "🎯 إعادة جدولة المهام المتعثرة (queued بدون تعيين)..."
STUCK_TASKS=$(sqlite3 "$FACT_DB" "
  SELECT id
  FROM tasks
  WHERE status = 'queued'
    AND id NOT IN (SELECT task_id FROM task_assignments)
  LIMIT 100;
")
REASSIGNED=0
DEFAULT_AGENT="system_architect"

if [ -n "$STUCK_TASKS" ]; then
  while IFS= read -r TID; do
    [ -z "$TID" ] && continue
    sqlite3 "$FACT_DB" "
      INSERT INTO task_assignments
        (task_id, agent_id, decision_reason, assigned_at, completed_at, result_status, result_notes)
      VALUES
        ($TID, '$DEFAULT_AGENT', 'auto-reschedule', datetime('now'), NULL, '', 'auto assigned by hf_task_manager');
    "
    REASSIGNED=$((REASSIGNED+1))
  done <<< "$STUCK_TASKS"
  log "   • تم إعادة جدولة $REASSIGNED مهمة إلى: $DEFAULT_AGENT"
else
  log "   • لا توجد مهام متعثرة بدون تعيين."
fi

log ""
log "📋 [4/4] ملخص الأداء بعد الإصلاحات..."

sqlite3 "$FACT_DB" -cmd ".headers on" -cmd ".mode column" \
  "SELECT status, COUNT(*) AS count
   FROM tasks
   GROUP BY status;" | tee -a "$REPORT_FILE"

SUCCESS_INT=$(sqlite3 "$FACT_DB" "
WITH s AS (
  SELECT
    SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END) AS d,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS f
  FROM tasks
)
SELECT CASE WHEN (d + f) = 0
            THEN 0
            ELSE CAST(100.0 * d / (d + f) AS INT)
       END
FROM s;
")

BACKLOG=$(sqlite3 "$FACT_DB" "
  SELECT COUNT(*)
  FROM tasks
  WHERE status IN ('queued','assigned');
")

log ""
log "📊 مؤشرات سريعة:"
log "  • معدل النجاح التقريبي: ${SUCCESS_INT}%"
log "  • حجم الـ backlog الحالي: $BACKLOG مهمة"

if [ "$SUCCESS_INT" -lt 80 ]; then
  log "  • توصية: التركيز على تحسين معالجة المهام الحرجة وتقليل الأخطاء."
else
  log "  • الأداء جيد، يمكن زيادة الحمل تدريجيًا."
fi

log ""
log "✅ التحليل الذكي اكتمل."
log "📄 التقرير الكامل: $REPORT_FILE"
