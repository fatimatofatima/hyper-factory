#!/usr/bin/env bash
# إصلاح / إنشاء جدول knowledge_items في knowledge.db و factory.db
set -euo pipefail

ROOT="/root/hyper-factory"
DB_KNOW="$ROOT/data/knowledge/knowledge.db"
DB_FACTORY="$ROOT/data/factory/factory.db"

fix_db() {
    local db="$1"
    local label="$2"

    if [ ! -f "$db" ]; then
        echo "⚠️ تخطي $label – الملف غير موجود: $db"
        return
    fi

    echo "📌 فحص / إصلاح knowledge_items في $label ($db)..."

    # هل الجدول موجود أصلاً؟
    if ! sqlite3 "$db" ".schema knowledge_items" >/dev/null 2>&1; then
        echo "🛠 إنشاء جدول جديد knowledge_items في $label..."
        sqlite3 "$db" <<'SQL'
CREATE TABLE IF NOT EXISTS knowledge_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title      TEXT NOT NULL,
    content    TEXT,
    category   TEXT,
    source     TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);
SQL
    else
        echo "ℹ️ جدول knowledge_items موجود – فحص الأعمدة في $label..."
        cols="$(sqlite3 "$db" "PRAGMA table_info(knowledge_items);" | awk -F'|' '{print $2}')"

        add_col() {
            local name="$1"
            local def="$2"
            if echo "$cols" | grep -qx "$name"; then
                echo "   ✅ العمود $name موجود."
            else
                echo "   🛠 إضافة العمود $name ..."
                sqlite3 "$db" "ALTER TABLE knowledge_items ADD COLUMN $name $def;"
            fi
        }

        # الأعمدة المطلوبة من hf_rapid_learning.sh
        add_col "title"      "TEXT"
        add_col "content"    "TEXT"
        add_col "category"   "TEXT"
        add_col "source"     "TEXT"
        add_col "created_at" "TEXT"
    fi

    echo "ℹ️ مخطط knowledge_items في $label بعد الإصلاح:"
    sqlite3 "$db" "PRAGMA table_info(knowledge_items);" | sed 's/^/   /'
    echo
}

fix_db "$DB_KNOW"    "knowledge.db"
fix_db "$DB_FACTORY" "factory.db"

echo "🏁 انتهى hf_fix_knowledge_items_schema.sh."
