#!/bin/bash
echo "🏭 نظام الإنتاجية القصوى - Multi-Agent Boost"

# إنشاء نسخ متعددة من العوامل لزيادة الإنتاجية
declare -A AGENT_COPIES=(
    ["debug_expert"]=5
    ["system_architect"]=3
    ["knowledge_spider"]=7
    ["technical_coach"]=4
    ["quality_engine"]=2
)

# تشغيل النسخ المتعددة
for agent in "${!AGENT_COPIES[@]}"; do
    copies=${AGENT_COPIES[$agent]}
    echo "🔄 تشغيل $copies نسخة من $agent..."
    
    for ((i=1; i<=copies; i++)); do
        if [ -f "./hf_run_${agent}.sh" ]; then
            AGENT_COPY="${agent}_boost_$i"
            cp "./hf_run_${agent}.sh" "./hf_run_${AGENT_COPY}.sh"
            chmod +x "./hf_run_${AGENT_COPY}.sh"
            
            # تسجيل النسخة في قاعدة البيانات
            sqlite3 /root/hyper-factory/data/factory/factory.db \
            "INSERT INTO agents (id, name, display_name, family, role, level, status) 
             VALUES ('${AGENT_COPY}', '${agent} Boost $i', '${agent} معزز $i', 
                    (SELECT family FROM agents WHERE id='${agent}' LIMIT 1),
                    (SELECT role FROM agents WHERE id='${agent}' LIMIT 1),
                    (SELECT level FROM agents WHERE id='${agent}' LIMIT 1),
                    'active');"
            
            ./hf_run_${AGENT_COPY}.sh &
            sleep 0.1.3
        fi
    done
done

# توليد مهام ضخمة
echo "🎯 توليد 200 مهمة ضخمة..."
cat > /tmp/massive_tasks.sql <<'SQL'
BEGIN TRANSACTION;
$(for i in {1..200}; do
    task_types=("debugging" "architecture" "knowledge" "training" "quality")
    families=("learning" "production" "research" "development")
    priorities=("high" "normal" "urgent")
    
    type_idx=$((RANDOM % 5))
    family_idx=$((RANDOM % 4))
    priority_idx=$((RANDOM % 3))
    
    echo "INSERT INTO tasks (created_at, source, description, task_type, type, family, priority, status) VALUES (datetime('now'), 'massive_production', 'مهمة إنتاجية $i', '${task_types[$type_idx]}', 'production', '${families[$family_idx]}', '${priorities[$priority_idx]}', 'queued');"
done)
COMMIT;
SQL

sqlite3 /root/hyper-factory/data/factory/factory.db < /tmp/massive_tasks.sql

# تشغيل نظام التوزيع الذكي
echo "🤖 تشغيل الموزع الذكي للمهام..."
./hf_factory_manager_loop.sh &

# نتائج فورية
sleep 0.1
echo ""
echo "💥 نظام الإنتاجية القصوى يعمل!"
echo "📊 الإحصائيات:"
sqlite3 /root/hyper-factory/data/factory/factory.db <<'SQL'
SELECT 
    (SELECT COUNT(*) FROM agents) as total_agents,
    (SELECT COUNT(*) FROM tasks) as total_tasks,
    (SELECT COUNT(*) FROM tasks WHERE status='queued') as queued_tasks,
    (SELECT COUNT(*) FROM tasks WHERE status='assigned') as assigned_tasks;
SQL

echo ""
echo "🚀 تشغيل لوحة التحكم المتقدمة..."
./hf_factory_dashboard.sh
