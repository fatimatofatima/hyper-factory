#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "📊 Hyper Factory – KPI Snapshot"
echo "================================"
echo "⏰ $(date)"
echo "📄 DB: $DB_PATH"
echo ""

# 0) تأكد من وجود قاعدة البيانات
if [ ! -f "$DB_PATH" ]; then
    echo "❌ قاعدة البيانات غير موجودة: $DB_PATH"
    exit 1
fi

# 1) تجهيز مسار التقرير
REPORT_DIR="$ROOT/reports/factory"
mkdir -p "$REPORT_DIR"
TS="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$REPORT_DIR/kpi_${TS}.txt"

{
  echo "📊 Hyper Factory – KPI Snapshot"
  echo "================================"
  echo "⏰ $(date)"
  echo "📄 DB: $DB_PATH"
  echo ""

  ########################################
  # 1) ملخص عام للمهام (Global Tasks)   #
  ########################################
  echo "1) ملخص عام للمهام:"
  echo "--------------------"

  echo "- إجمالي عدد المهام:"
  sqlite3 -header -column "$DB_PATH" "SELECT COUNT(*) AS total_tasks FROM tasks;" \
    || echo "⚠️ تعذر قراءة إجمالي المهام"
  echo ""

  echo "- توزيع الحالات (status):"
  sqlite3 -header -column "$DB_PATH" "
    SELECT 
      status, 
      COUNT(*) AS count
    FROM tasks
    GROUP BY status
    ORDER BY status;
  " || echo "⚠️ تعذر قراءة توزيع الحالات"
  echo ""

  echo "- نسبة النجاح + الـ backlog:"
  sqlite3 -header -column "$DB_PATH" "
    SELECT
      SUM(CASE WHEN status = 'done'   THEN 1 ELSE 0 END) AS done,
      SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed,
      SUM(CASE WHEN status IN ('assigned','queued') THEN 1 ELSE 0 END) AS backlog,
      ROUND(
        CASE
          WHEN SUM(CASE WHEN status IN ('done','failed') THEN 1 ELSE 0 END) = 0
          THEN 0.0
          ELSE 100.0 * 
               SUM(CASE WHEN status = 'done' THEN 1 ELSE 0 END)
               / SUM(CASE WHEN status IN ('done','failed') THEN 1 ELSE 0 END)
        END
      , 2) AS success_rate_percent
    FROM tasks;
  " || echo "⚠️ تعذر حساب نسبة النجاح العالمية"
  echo ""

  ########################################
  # 2) توزيع المهام حسب النوع           #
  ########################################
  echo "2) توزيع المهام حسب النوع (type):"
  echo "---------------------------------"
  sqlite3 -header -column "$DB_PATH" "
    SELECT
      type,
      COUNT(*) AS total,
      SUM(CASE WHEN status = 'done'   THEN 1 ELSE 0 END) AS done,
      SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed
    FROM tasks
    GROUP BY type
    ORDER BY total DESC;
  " || echo "⚠️ تعذر قراءة توزيع المهام حسب النوع"
  echo ""

  ########################################
  # 3) أفضل العمال حسب عدد التشغيل      #
  ########################################
  echo "3) أفضل 10 عمال حسب عدد التشغيل:"
  echo "--------------------------------"
  sqlite3 -header -column "$DB_PATH" "
    SELECT
      id           AS agent_id,
      display_name AS name,
      family,
      role,
      level,
      success_rate,
      total_runs
    FROM agents
    ORDER BY total_runs DESC
    LIMIT 10;
  " || echo "⚠️ تعذر قراءة أفضل العمال"
  echo ""

  ########################################
  # 4) أسوأ العمال حسب نسبة النجاح      #
  ########################################
  echo "4) أسوأ 5 عمال (total_runs >= 5) حسب نسبة النجاح:"
  echo "--------------------------------------------------"
  sqlite3 -header -column "$DB_PATH" "
    SELECT
      id           AS agent_id,
      display_name AS name,
      success_rate,
      total_runs
    FROM agents
    WHERE total_runs >= 5
    ORDER BY success_rate ASC, total_runs DESC
    LIMIT 5;
  " || echo "⚠️ تعذر قراءة أسوأ العمال"
  echo ""

  ########################################
  # 5) توزيع التعيينات على العمال       #
  ########################################
  echo "5) توزيع التعيينات على العمال (task_assignments):"
  echo "--------------------------------------------------"
  sqlite3 -header -column "$DB_PATH" "
    SELECT
      agent_id,
      COUNT(*) AS assignments
    FROM task_assignments
    GROUP BY agent_id
    ORDER BY assignments DESC
    LIMIT 10;
  " || echo "⚠️ تعذر قراءة توزيع التعيينات على العمال"
  echo ""

} | tee "$REPORT_FILE"

echo ""
echo "✅ تم حفظ تقرير KPI في:"
echo "   $REPORT_FILE"
