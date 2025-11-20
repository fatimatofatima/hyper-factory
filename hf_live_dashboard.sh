#!/bin/bash
while true; do
    clear
    echo "📊 Hyper Factory Live Dashboard"
    echo "================================"
    echo "⏰ $(date '+%Y-%m-%d %H:%M:%S')"
    
    # إحصائيات حية
    sqlite3 data/factory/factory.db "
    SELECT 
        '🎯 المهام: ' || COUNT(*) as total,
        '✅ المكتملة: ' || SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) as done,
        '🔄 قيد التنفيذ: ' || SUM(CASE WHEN status='assigned' THEN 1 ELSE 0 END) as assigned,
        '⏳ في الانتظار: ' || SUM(CASE WHEN status='queued' THEN 1 ELSE 0 END) as queued,
        '👥 العمال النشطين: ' || (SELECT COUNT(*) FROM agents WHERE total_runs > 0) as active_agents
    FROM tasks;
    "
    
    echo ""
    echo "📈 العمال الأكثر نشاطاً:"
    sqlite3 -header -column data/factory/factory.db "
    SELECT display_name, total_runs, success_rate 
    FROM agents 
    WHERE total_runs > 0 
    ORDER BY total_runs DESC 
    LIMIT 5;
    "
    
    sleep 10
done
