#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🧱 Hyper Factory – Register Core Agents"
echo "======================================="
echo "⏰ $(date)"
echo "📄 DB: $DB_PATH"
echo ""

if [ ! -f "$DB_PATH" ]; then
    echo "❌ قاعدة البيانات غير موجودة: $DB_PATH"
    exit 1
fi

echo "📋 فحص جدول agents..."
TABLES=$(sqlite3 "$DB_PATH" ".tables" 2>/dev/null || echo "")
echo "   Tables: $TABLES"
echo ""

if ! echo "$TABLES" | grep -qw "agents"; then
    echo "❌ جدول agents غير موجود - لا يمكن التسجيل."
    exit 1
fi

echo "👷 تسجيل عامل مهندس قواعد البيانات (db_architect)..."

sqlite3 "$DB_PATH" "
INSERT OR IGNORE INTO agents (
    id, display_name, family, role, level, success_rate, total_runs, priority_weight
) VALUES (
    'db_architect',
    'مهندس قواعد البيانات',
    'data_platform',
    'database_architect & knowledge_modeler',
    'senior',
    0.0,
    0,
    1.8
);
"

echo ""
echo "📊 حالة عامل db_architect:"
sqlite3 "$DB_PATH" -header -column "
SELECT 
    id,
    display_name,
    family,
    role,
    level,
    success_rate,
    total_runs,
    priority_weight,
    last_updated
FROM agents
WHERE id = 'db_architect';
"

echo ""
echo "✅ Registration finished."
