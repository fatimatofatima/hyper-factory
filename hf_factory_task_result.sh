#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"
SKILLS_PY="$ROOT/tools/hf_skills_engine.py"   # Hook مستقبلي لرفع المهارات (اختياري الآن)

usage() {
  cat << USAGE
Hyper Factory – Task Result Logger
==================================
استخدام:

  $0 <task_id> <agent_id> <result> [notes]

  <task_id>  : رقم المهمة في جدول tasks (INTEGER)
  <agent_id> : معرف العامل (مثال: debug_expert, system_architect, technical_coach)
  <result>   : success | fail
  [notes]    : ملاحظات نصية اختيارية عن النتيجة

وظيفة السكربت:
  1) تحديث جدول task_assignments (result_status, result_notes, completed_at).
  2) تحديث حالة المهمة في tasks إلى done أو failed.
  3) (اختياري لاحقًا) استدعاء محرك المهارات لرفع/تعديل مستوى مهارة العامل بناءً على النتيجة.
USAGE
}

task_id="$1"
agent_id="$2"
result="$3"
shift 3 || true
notes="$*"

if [ -z "$task_id" ] || [ -z "$agent_id" ] || [ -z "$result" ]; then
  usage
  exit 1
fi

if [ "$result" != "success" ] && [ "$result" != "fail" ]; then
  echo "⚠️ القيمة result يجب أن تكون: success أو fail"
  exit 1
fi

if [ ! -f "$DB_PATH" ]; then
  echo "❌ قاعدة بيانات المصنع غير موجودة: $DB_PATH"
  exit 1
fi

now="$(date -Iseconds)"

echo "📝 تسجيل نتيجة مهمة:"
echo "  task_id : $task_id"
echo "  agent   : $agent_id"
echo "  result  : $result"
echo "  notes   : ${notes:-(بدون ملاحظات)}"
echo ""

sqlite3 "$DB_PATH" << SQL
UPDATE task_assignments
SET
  result_status = '$result',
  result_notes  = '$notes',
  completed_at  = '$now'
WHERE task_id = $task_id
  AND agent_id = '$agent_id';

UPDATE tasks
SET status = CASE
    WHEN '$result' = 'success' THEN 'done'
    ELSE 'failed'
  END
WHERE id = $task_id;
SQL

echo "✅ تم تحديث حالة المهمة والـ assignment في قاعدة البيانات."

# ===========================
# Hook مبدئي لمحرك المهارات
# ===========================
# الفكرة:
#   - عند نجاح المهمة، نرفع Skill معيّنة للعامل (حسب نوع المهمة).
#   - الربط الفعلي مع hf_skills_engine.py سيتم في خطوة تالية حسب سياسة المهارات.

if [ "$result" = "success" ] && [ -x "$SKILLS_PY" ]; then
  echo "ℹ️ Hook رفع المهارات غير مفعّل بعد (سيتم ربطه في خطوة لاحقة)."
  # مثال مستقبلي متوقع (سيتم تفعيله لاحقاً بعد تعريف mapping task_type → skill_id):
  # python3 "$SKILLS_PY" apply-task-result "$agent_id" "$task_id" "success" || echo "⚠️ فشل تحديث المهارات (تحذير فقط)."
else
  echo "ℹ️ لم يتم استدعاء محرك المهارات في هذه النسخة (placeholder)."
fi
