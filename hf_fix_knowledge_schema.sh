#!/usr/bin/env bash
# إصلاح جدول knowledge_items وضمان وجود العمود content

set -euo pipefail

ROOT="/root/hyper-factory"
DB_KNOW="$ROOT/data/knowledge/knowledge.db"

if [ ! -f "$DB_KNOW" ]; then
    echo "⚠️ knowledge.db غير موجود: $DB_KNOW"
    exit 1
fi

echo "📌 إصلاح مخطط knowledge_items في $DB_KNOW ..."

# لو الجدول مش موجود: إنشاؤه من الصفر
if ! sqlite3 "$DB_KNOW" ".schema knowledge_items" >/dev/null 2>&1; then
    echo "🛠 إنشاء جدول knowledge_items من الصفر..."
    sqlite3 "$DB_KNOW" <<'SQL'
CREATE TABLE knowledge_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title     TEXT NOT NULL,
    content   TEXT DEFAULT '',
    category  TEXT,
    source    TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
SQL
else
    # لو موجود: تأكد من وجود العمود content، لو مش موجود أضفه
    if ! sqlite3 "$DB_KNOW" "PRAGMA table_info(knowledge_items);" \
        | awk -F'|' '{print $2}' | grep -q '^content$'; then
        echo "🛠 إضافة العمود content إلى knowledge_items ..."
        sqlite3 "$DB_KNOW" "ALTER TABLE knowledge_items ADD COLUMN content TEXT DEFAULT '';"
    else
        echo "✅ العمود content موجود بالفعل في knowledge_items."
    fi
fi

echo "ℹ️ schema بعد الإصلاح:"
sqlite3 "$DB_KNOW" ".schema knowledge_items"

echo "🏁 انتهى hf_fix_knowledge_schema.sh."
