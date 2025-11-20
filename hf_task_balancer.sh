#!/bin/bash
echo "⚖️ موازنة توزيع المهام..."
sqlite3 data/factory/factory.db "
-- إعادة تعيين المهام المعطلة
UPDATE tasks SET status='queued', priority='high' 
WHERE status='assigned' AND created_at < datetime('now', '-30 minutes');

-- تخصيص مهام للعمال غير النشطين
UPDATE tasks SET status='queued' 
WHERE status='queued' AND task_type IN ('knowledge', 'general') 
LIMIT 10;
"
echo "✅ تمت موازنة المهام"
