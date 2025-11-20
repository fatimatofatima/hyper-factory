#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🔄 Hyper Factory – Simple Performance Updater"
echo "============================================="
echo "⏰ $(date)"

# فحص بسيط للبيانات
echo ""
echo "📊 ملخص العمال الحالي:"
sqlite3 -header -column "$DB_PATH" "
SELECT 
    id as 'ID',
    name as 'Name',
    family as 'Family', 
    success_rate as 'Success%',
    total_runs as 'Runs'
FROM agents 
WHERE total_runs > 0 
ORDER BY total_runs DESC 
LIMIT 10;
" 2>/dev/null || echo "⚠️ تعذر قراءة بيانات العمال"

echo ""
echo "✅ Simple Performance Check اكتمل"
