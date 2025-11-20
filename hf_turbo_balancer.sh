#!/bin/bash
echo "⚡ TURBO BALANCER - توزيع المهام بسرعة"

# إعادة توزيع المهام من knowledge_spider إلى عوامل أخرى
sqlite3 data/factory/factory.db "
UPDATE tasks SET agent_id = 'system_architect' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 500;

UPDATE tasks SET agent_id = 'debug_expert' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 500;

UPDATE tasks SET agent_id = 'technical_coach' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 300;
"

echo "✅ تمت الموازنة التوربو"
