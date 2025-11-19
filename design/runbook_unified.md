# Runbook موحد - Hyper Factory

## التشغيل السريع
\`\`\`bash
# 1. تشغيل المصنع (اليدوي الأساسي)
./run_basic_with_memory.sh

# 2. تشغيل لوحة الإدارة
./hf_run_manager_dashboard.sh

# 3. فحص الصحة
./scripts/core/health_monitor.sh
\`\`\`

## سكربتات hf_run_* الرئيسية
- \`hf_run_manager_dashboard.sh\` - لوحة التحكم اليومية
- \`hf_run_quality_worker.sh\` - عامل الجودة
- \`hf_run_offline_learner.sh\` - التعلم الآلي
- \`hf_run_system_architect.sh\` - المهندس المعماري
- \`hf_run_apply_lessons.sh\` - تطبيق الدروس

## استكشاف الأخطاء
\`\`\`bash
# إذا فشل التشغيل:
./scripts/core/health_monitor.sh

# فحص الذاكرة:
sqlite3 data/knowledge/knowledge.db "SELECT item_type, COUNT(*) FROM knowledge_items GROUP BY item_type;"

# فحص العمال:
cat ai/memory/people/agents_levels.json | jq '.'
\`\`\`

## المراقبة اليومية
1. افحص \`reports/management/*_manager_daily_overview.txt\`
2. تأكد من وجود تقارير حديثة
3. تأكد من تحديث knowledge_items
