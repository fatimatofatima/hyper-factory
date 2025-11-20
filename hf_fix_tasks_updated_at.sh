#!/usr/bin/env bash
set -Eeuo pipefail

DB="data/factory/factory.db"

echo "🔧 HF – إصلاح عمود updated_at في جدول tasks"

if [[ ! -f "$DB" ]]; then
  echo "❌ قاعدة البيانات غير موجودة: $DB"
  exit 1
fi

echo "📋 هيكل جدول tasks قبل التعديل:"
sqlite3 "$DB" "PRAGMA table_info(tasks);"

HAS_COL=$(sqlite3 "$DB" "PRAGMA table_info(tasks);" | awk -F'|' '$2=="updated_at"{print $2}' || true)

if [[ -n "$HAS_COL" ]]; then
  echo "✅ عمود updated_at موجود بالفعل – لا حاجة لتعديله"
  exit 0
fi

echo "➕ إضافة العمود بدون DEFAULT (لتفادي خطأ non-constant default)"
sqlite3 "$DB" "ALTER TABLE tasks ADD COLUMN updated_at TEXT;"

echo "⏱️ تعبئة العمود للقيم الحالية (باستخدام created_at إن وجدت أو الوقت الحالي)"
HAS_CREATED=$(sqlite3 "$DB" "PRAGMA table_info(tasks);" | awk -F'|' '$2=="created_at"{print $2}' || true)

if [[ -n "$HAS_CREATED" ]]; then
  sqlite3 "$DB" "UPDATE tasks SET updated_at = created_at WHERE updated_at IS NULL;"
else
  sqlite3 "$DB" "UPDATE tasks SET updated_at = datetime('now') WHERE updated_at IS NULL;"
fi

echo "📋 هيكل جدول tasks بعد التعديل:"
sqlite3 "$DB" "PRAGMA table_info(tasks);"

echo "✅ تم إصلاح عمود updated_at بنجاح"
