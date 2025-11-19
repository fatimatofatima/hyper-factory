#!/usr/bin/env bash
# سكربت إنشاء ملفات الأولوية وعرضها مباشرة

set -euo pipefail

echo "🚀 إنشاء ملفات الأولوية لـ Hyper Factory..."
echo "=============================================="
echo

# تأكيد وجود المجلدات
mkdir -p design
mkdir -p reports

########################################
# 1) ملف التعريف الرسمي hf_overview.md
########################################
echo "1. 📄 إنشاء design/hf_overview.md..."
cat > design/hf_overview.md << 'OVERVIEW'
# Hyper Factory - النظام التشغيلي

## 🚀 نقطة الدخول الرئيسية
- **التشغيل اليومي**: `./run_basic_with_memory.sh`
- **لوحة الإدارة**: `./hf_run_manager_dashboard.sh`
- **فحص الصحة**: `./scripts/core/health_monitor.sh`

## 📘 دليل أوسع للنماذج
- `design/hf_ai_model_guide.md`  ← دليل ثابت يشرح الصورة الكاملة للنماذج (AI Model Guide)

## 🏗 المكونات الأساسية
- **الذاكرة**: `data/knowledge/knowledge.db` (knowledge_items)
- **العمال**: `ai/memory/people/agents_levels.json` + مستويات في DB
- **التقارير**: `reports/management/*_manager_daily_overview.*`
- **التشغيل**: حزمة `hf_run_*.sh`

## 📊 حالة النظام الحالية
- خط الإنتاج الأساسي: ✅ جاهز (ingestor→processor→analyzer→reporter)
- نظام الذاكرة: ✅ نشط
- لوحة الإدارة: ✅ تولّد تقارير
- التشغيل الآلي: ⚠️ يحتاج systemd/cron

## 🛠 السيناريوهات التشغيلية
1. **تشغيل يدوي**: `./run_basic_with_memory.sh`
2. **مراقبة**: `./hf_run_manager_dashboard.sh`
3. **تطبيق الدروس**: `./hf_run_apply_lessons.sh`

## 📁 الهيكل الرئيسي
\`\`\`
hyper-factory/
├── apps/backend_coach/          # الخدمة الأساسية (port 9090)
├── data/knowledge/knowledge.db  # قاعدة المعرفة
├── ai/memory/people/            # تعريفات العمال
├── scripts/core/                # سكربتات التشغيل
├── reports/management/          # تقارير الإدارة
└── hf_run_*.sh                  # سكربتات التشغيل الموحدة
\`\`\`
OVERVIEW

echo "✅ تم إنشاء design/hf_overview.md"
echo "-----------------------------------"
cat design/hf_overview.md
echo

########################################
# 2) تعريف الصحة التشغيلية health_summary.md
########################################
echo "2. 📊 إنشاء reports/health_summary.md..."
cat > reports/health_summary.md << 'HEALTH'
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
HEALTH

echo "✅ تم إنشاء reports/health_summary.md"
echo "--------------------------------------"
cat reports/health_summary.md
echo

########################################
# 3) نموذج systemd (example فقط)
########################################
echo "3. ⚙️ إنشاء design/hyper-factory.service.example..."
cat > design/hyper-factory.service.example << 'SERVICE'
[Unit]
Description=Hyper Factory Core Services
After=network.target

[Service]
Type=oneshot
User=root
WorkingDirectory=/root/hyper-factory
ExecStart=/bin/bash -c "./run_basic_with_memory.sh"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

echo "✅ تم إنشاء design/hyper-factory.service.example"
echo "------------------------------------------------"
cat design/hyper-factory.service.example
echo

########################################
# 4) Runbook موحد runbook_unified.md
########################################
echo "4. 📖 إنشاء design/runbook_unified.md..."
cat > design/runbook_unified.md << 'RUNBOOK'
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
RUNBOOK

echo "✅ تم إنشاء design/runbook_unified.md"
echo "--------------------------------------"
cat design/runbook_unified.md
echo

########################################
# ختام
########################################
echo "🎉 تم إنشاء جميع ملفات الأولوية بنجاح!"
echo "======================================"
echo "الملفات التي تم إنشاؤها:"
echo "1. design/hf_overview.md                 - ملف التعريف الرسمي"
echo "2. reports/health_summary.md             - تعريف الصحة التشغيلية"
echo "3. design/hyper-factory.service.example  - نموذج systemd"
echo "4. design/runbook_unified.md             - Runbook موحد"
echo
echo "📁 يمكنك مراجعتها في:"
find design/ reports/ -type f \( -name "hf_overview.md" -o -name "health_summary.md" -o -name "runbook_unified.md" -o -name "hyper-factory.service.example" \) 2>/dev/null
