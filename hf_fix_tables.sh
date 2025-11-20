#!/bin/bash
echo "🔧 إصلاح هيكل الجداول (نسخة SQLite متوافقة)..."
echo "=============================================="

# نسخة متوافقة مع SQLite القديم
sqlite3 data/factory/factory.db "
-- التحقق من وجود الأعمدة أولاً
BEGIN TRANSACTION;

-- إضافة success_runs إذا لم تكن موجودة
CREATE TEMPORARY TABLE temp_agents AS SELECT * FROM agents LIMIT 0;
PRAGMA table_info(temp_agents);
DROP TABLE temp_agents;

-- محاولة إضافة العمود (سيفشل إذا كان موجوداً لكن هذا مقبول)
ALTER TABLE agents ADD COLUMN success_runs INTEGER DEFAULT 0;

-- محاولة إضافة salary_index  
ALTER TABLE agents ADD COLUMN salary_index REAL DEFAULT 1.0;

-- تحديث البيانات
UPDATE agents SET success_runs = ROUND(total_runs * (success_rate / 100.0)) WHERE total_runs > 0;

COMMIT;
"

echo "✅ تم محاولة إصلاح الجداول"
echo "📊 التحقق من النتائج:"
sqlite3 data/factory/factory.db "SELECT id, display_name, total_runs, success_rate, success_runs FROM agents LIMIT 5;"
