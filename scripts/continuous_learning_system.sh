#!/bin/bash
echo "🔄 نظام التعلم المستمر لـ Debug Expert"
echo "====================================="

# 1. تحديث المعرفة من الويب
echo "🌐 يجمع معرفة جديدة من الإنترنت..."
python3 tools/hf_advanced_web_spider.py

# 2. معالجة المعرفة الجديدة
echo "🧠 يعالج المعرفة المجموعة..."
python3 tools/hf_knowledge_processor.py

# 3. تحديث الخبير بالمعرفة الجديدة
echo "🤖 يحدث Debug Expert بالمعرفة الجديدة..."
python3 -c "
from tools.hf_knowledge_debug_expert import KnowledgeDebugExpert
expert = KnowledgeDebugExpert()
report = expert.generate_performance_report()
print('✅ تم تحديث الخبير بالمعرفة الجديدة')
print('📊 التقرير الحالي:')
for key, value in report.items():
    print(f'   {key}: {value}')
"

# 4. اختبار التحسن
echo "🧪 يختبر التحسن في الأداء..."
./scripts/compare_debug_experts.sh

echo "🎉 اكتمل التعلم المستمر!"
