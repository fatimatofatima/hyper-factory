#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

echo "🕷️ Hyper Factory – Spiders Family"
echo "================================"

# أنواع الـ Spiders المختلفة
SPIDER_TYPES=("code" "data" "devops" "docs")

for spider_type in "${SPIDER_TYPES[@]}"; do
    echo "🔍 تشغيل $spider_type spider..."
    
    # إنشاء مهمة معرفة لكل نوع
    sqlite3 "$DB_PATH" "
    INSERT INTO tasks (created_at, source, description, task_type, priority, status)
    VALUES (
        CURRENT_TIMESTAMP,
        'spiders_family',
        'جمع معرفة $spider_type - تحديث تلقائي',
        'knowledge',
        'normal',
        'queued'
    );"
    
    echo "✅ تم إنشاء مهمة $spider_type"
done

echo "📊 إحصائيات الـ Spiders:"
sqlite3 "$DB_PATH" "
SELECT '🕷️ عائلة الـ Spiders: ' || COUNT(*) || ' مهمة معرفة نشطة' 
FROM tasks 
WHERE task_type = 'knowledge' 
AND status IN ('queued', 'assigned')
AND source = 'spiders_family';"

echo "✅ Spiders Family اكتمل"
