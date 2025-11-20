#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

aid="$1"
status="$2"
note="${3:-}"

if [ -z "$aid" ] || [ -z "$status" ]; then
  echo "استخدام:"
  echo "  $0 <assignment_id> <success|failed> [note]"
  exit 1
fi

if [ "$status" != "success" ] && [ "$status" != "failed" ]; then
  echo "⚠️ result_status يجب أن يكون success أو failed فقط."
  exit 1
fi

if [ ! -f "$DB_PATH" ]; then
  echo "⚠️ قاعدة بيانات المصنع غير موجودة: $DB_PATH"
  echo "   شغّل: ./hf_factory_cli.sh init-db"
  exit 1
fi

# الهروب من علامات ' فى الملاحظة
note_escaped="${note//\'/\'\'}"

now=$(date --iso-8601=seconds)

echo "📝 تحديث نتيجة التعيين:"
echo "   assignment_id : $aid"
echo "   result_status : $status"
echo "   note          : $note"

# تحقق أن التعيين موجود
exists=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM task_assignments WHERE id = $aid;" 2>/dev/null || echo 0)
if [ "$exists" -eq 0 ]; then
  echo "❌ لا يوجد تعيين بهذه الـ id في task_assignments: $aid"
  exit 1
fi

# تحديث task_assignments + tasks
sqlite3 "$DB_PATH" << SQL
UPDATE task_assignments
SET result_status = '$status',
    completed_at = '$now',
    result_notes = '$note_escaped'
WHERE id = $aid;

UPDATE tasks
SET status = CASE
    WHEN '$status' = 'success' THEN 'done'
    ELSE 'failed'
  END
WHERE id = (SELECT task_id FROM task_assignments WHERE id = $aid);
SQL

echo "✅ تم تسجيل نتيجة التعيين بنجاح."
