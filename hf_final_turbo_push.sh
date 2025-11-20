#!/bin/bash
echo "🎯 FINAL TURBO PUSH - لتحقيق 20%+ معدل إنجاز"

# توزيع 10,000 مهمة إضافية
sqlite3 data/factory/factory.db "
-- توزيع مكثف على جميع العوامل
UPDATE tasks SET agent_id = 'system_architect' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 3000;

UPDATE tasks SET agent_id = 'debug_expert' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 3000;

UPDATE tasks SET agent_id = 'technical_coach' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 2000;

UPDATE tasks SET agent_id = 'quality_engine' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 1000;

UPDATE tasks SET agent_id = 'system_architect_boost_1' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 500;

UPDATE tasks SET agent_id = 'debug_expert_boost_1' 
WHERE agent_id = 'knowledge_spider' AND status = 'queued' 
LIMIT 500;
"

echo "✅ تم توزيع 10,000 مهمة نهائية"
