#!/bin/bash
echo "⚡ TURBO BALANCE EXTRA - توزيع مكثف"

# توزيع 2000 مهمة إضافية
sqlite3 data/factory/factory.db "
-- توزيع على system_architect
UPDATE tasks SET agent_id = 'system_architect' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 700;

-- توزيع على debug_expert  
UPDATE tasks SET agent_id = 'debug_expert' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 700;

-- توزيع على technical_coach
UPDATE tasks SET agent_id = 'technical_coach' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 600;
"

echo "✅ تم توزيع 2000 مهمة إضافية"
