#!/usr/bin/env bash
# إصلاح مخطط جدول agents بإضافة display_name وربطه بالـ name

set -u

ROOT="/root/hyper-factory"
DB_FACTORY="$ROOT/data/factory/factory.db"
DB_KNOW="$ROOT/data/knowledge/knowledge.db"

fix_one_db() {
    local db="$1"
    local label="$2"

    if [ ! -f "$db" ]; then
        echo "⚠️ تخطي $label – الملف غير موجود: $db"
        return
    fi

    echo "📌 فحص جدول agents في $label ($db)..."

    if ! sqlite3 "$db" ".schema agents" >/dev/null 2>&1; then
        echo "⚠️ جدول agents غير موجود في $label – تخطي."
        return
    fi

    local has_display
    has_display="$(sqlite3 "$db" "PRAGMA table_info(agents);" 2>/dev/null | awk -F'|' '$2=="display_name"{print "yes"}')"

    if [ "$has_display" != "yes" ]; then
        echo "🛠 إضافة عمود display_name إلى agents في $label..."
        sqlite3 "$db" "ALTER TABLE agents ADD COLUMN display_name TEXT;" 2>/dev/null || {
            echo "❌ فشل ALTER TABLE في $label – راجع المخطط يدويًا."
            return
        }
        echo "🔁 تعبئة display_name من name في $label..."
        sqlite3 "$db" "UPDATE agents SET display_name = COALESCE(display_name, name);" 2>/dev/null || {
            echo "❌ فشل UPDATE في $label – راجع البيانات."
            return
        }
        echo "✅ تم إضافة وتعبئة display_name في $label."
    else
        echo "✅ display_name موجود بالفعل في $label – لا تعديل."
    fi

    echo "ℹ️ مخطط agents في $label بعد الإصلاح:"
    sqlite3 "$db" "PRAGMA table_info(agents);"
    echo
}

fix_one_db "$DB_FACTORY" "factory.db"
fix_one_db "$DB_KNOW"    "knowledge.db"

echo "🏁 انتهى hf_fix_agents_schema.sh."
