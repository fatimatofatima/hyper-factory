#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

DB_FACTORY="$ROOT/data/factory/factory.db"
DB_KNOW="$ROOT/data/knowledge/knowledge.db"
FACTORY_CLI="$ROOT/hf_factory_cli.sh"

echo "🕸️ Hyper Factory – Spider → Factory Bridge"
echo "=========================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

if [ ! -x "$FACTORY_CLI" ]; then
  echo "❌ hf_factory_cli.sh غير موجود أو غير قابل للتنفيذ."
  exit 1
fi

if [ ! -f "$DB_FACTORY" ]; then
  echo "ℹ️ لا توجد factory.db – تشغيل init-db أولًا..."
  ./hf_factory_cli.sh init-db
fi

if [ ! -f "$DB_FACTORY" ]; then
  echo "❌ factory.db ما زالت غير موجودة – إيقاف."
  exit 1
fi

if [ ! -f "$DB_KNOW" ]; then
  echo "ℹ️ knowledge.db غير موجودة – لا توجد صفوف لتحويلها لمهام."
  exit 0
fi

echo "1) البحث عن جدول knowledge_items داخل knowledge.db ..."
has_items_table=$(sqlite3 "$DB_KNOW" "SELECT name FROM sqlite_master WHERE type='table' AND name='knowledge_items';" 2>/dev/null || true)

if [ -z "$has_items_table" ]; then
  echo "   ℹ️ جدول knowledge_items غير موجود – لا تحويل صفوف فردية، فقط نحتفظ بهذا كتحذير لطيف."
  exit 0
fi

echo "   ✅ تم العثور على جدول knowledge_items."

# دالة مساعدة لإنشاء مهمة لمعرف صف واحد
create_task_for_item() {
  local item_id="$1"
  local title="$2"

  local tag="KI${item_id}"

  local exists
  exists=$(sqlite3 "$DB_FACTORY" "SELECT COUNT(*) FROM tasks WHERE description LIKE '%#$tag%';" 2>/dev/null || echo 0)

  if [ "$exists" -gt 0 ]; then
    echo "   • الصف $item_id (#$tag) لديه مهمة مسبقًا – تخطى."
    return
  fi

  local desc="مراجعة وتثبيت المعرفة للعنصر المعرفى رقم ${item_id}: ${title} #$tag"
  echo "   ➜ إنشاء مهمة معرفة للصف ${item_id} ..."
  ./hf_factory_cli.sh new "$desc" "normal"
}

echo ""
echo "2) اختيار عينة صفوف تحتاج مراجعة من knowledge_items ..."

# نحاول اختيار صفوف بحالة غير 'reviewed' لو الكولم موجود
has_status_col=$(sqlite3 "$DB_KNOW" "PRAGMA table_info('knowledge_items');" 2>/dev/null | awk -F'|' '$2=="status"{print $2}' || true)

if [ -n "$has_status_col" ]; then
  query="SELECT id, COALESCE(title, source, ''), COALESCE(status,'')
         FROM knowledge_items
         WHERE status IS NULL OR status <> 'reviewed'
         ORDER BY id DESC
         LIMIT 30;"
else
  query="SELECT id, COALESCE(title, source, ''), '' 
         FROM knowledge_items
         ORDER BY id DESC
         LIMIT 30;"
fi

count_rows=0
sqlite3 -separator '|' "$DB_KNOW" "$query" 2>/dev/null | while IFS='|' read -r iid ititle istatus; do
  [ -z "$iid" ] && continue
  count_rows=$((count_rows + 1))
  # تقصير العنوان لو طويل
  short_title="$ititle"
  short_title="${short_title:0:120}"
  create_task_for_item "$iid" "$short_title"
done

echo ""
echo "3) ملخص:"
echo "   ▸ عدد الصفوف المعالجة (محاولة): $count_rows"

echo ""
echo "✅ Spider → Factory Bridge انتهى."
