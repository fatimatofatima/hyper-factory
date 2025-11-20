#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FACT_DB="$ROOT/data/factory/factory.db"

NUM="${1:-100}"

echo "🎯 Hyper Factory – Load Test"
echo "============================"
echo "⏰ $(date)"
echo "📄 FACTORY DB: $FACT_DB"
echo "📦 عدد المهام التجريبية المطلوب إنشاؤها: $NUM"
echo ""

if [ ! -f "$FACT_DB" ]; then
  echo "❌ factory.db غير موجود: $FACT_DB"
  exit 1
fi

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "❌ sqlite3 غير مثبت"
  exit 1
fi

TYPES=(knowledge general debug architecture quality coaching)
PRIORITIES=(low normal high)

COUNT=0
for i in $(seq 1 "$NUM"); do
  idx_type=$((RANDOM % ${#TYPES[@]}))
  TASK_TYPE="${TYPES[$idx_type]}"

  idx_prio=$((RANDOM % ${#PRIORITIES[@]}))
  PRIORITY="${PRIORITIES[$idx_prio]}"

  DESC="Load test task #$i ($TASK_TYPE/$PRIORITY)"

  TASK_ID=$(sqlite3 "$FACT_DB" "
    INSERT INTO tasks (created_at, source, description, task_type, priority, status)
    VALUES (datetime('now'),
            'system:load_test',
            '$DESC',
            '$TASK_TYPE',
            '$PRIORITY',
            'queued');
    SELECT last_insert_rowid();
  ")

  COUNT=$((COUNT+1))
done

TOTAL=$(sqlite3 "$FACT_DB" "SELECT COUNT(*) FROM tasks;")

echo ""
echo "✅ تم إنشاء $COUNT مهمة تجريبية من مصدر system:load_test."
echo "📊 إجمالي المهام الآن في الجدول tasks: $TOTAL"
