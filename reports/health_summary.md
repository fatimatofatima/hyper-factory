# Health Status Definition

## ✅ المصنع سليم عندما:
- \`knowledge.db\` قابلة للقراءة والكتابة
- \`backend_coach\` يستجيب على port 9090
- \`agents_levels.json\` سليم ومتكامل مع DB
- آخر تقرير manager أقل من 2 ساعة

## ⚠️ يحتاج تدخل عندما:
- health_check_report.json أقدم من 6 ساعات
- خطأ في \`run_basic_with_memory.sh\`
- تناقض بين agents_levels.json و knowledge_items

## 🔴 توقف كامل عندما:
- knowledge.db تالفة
- جميع سكربتات hf_run_* فاشلة
- لا توجد تقارير في آخر 24 ساعة

## 🔍 فحص سريع:
\`\`\`bash
# فحص الخدمات الأساسية
./scripts/core/health_monitor.sh

# فحص قاعدة المعرفة
sqlite3 data/knowledge/knowledge.db "SELECT COUNT(*) FROM knowledge_items;"

# فحص العمال
jq length ai/memory/people/agents_levels.json

# أحدث تقرير
ls -la reports/management/*_manager_daily_overview.* | tail -1
\`\`\`
