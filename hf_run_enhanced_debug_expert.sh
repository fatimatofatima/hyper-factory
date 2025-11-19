#!/bin/bash
echo "🤖 تشغيل Knowledge-Enhanced Debug Expert"
echo "========================================"

# استخدام الخبير المدعوم بالمعرفة
python3 tools/hf_knowledge_debug_expert.py

# إذا تم تمرير خطأ كمعامل، معالجته
if [ $# -gt 0 ]; then
    ERROR_MESSAGE="$*"
    echo ""
    echo "🔍 يحلل الخطأ الممرر: $ERROR_MESSAGE"
    python3 -c "
from tools.hf_knowledge_debug_expert import KnowledgeDebugExpert
expert = KnowledgeDebugExpert()
result = expert.analyze_error_with_knowledge('$ERROR_MESSAGE')
if result:
    print('💡 الحل:', result['solution'])
    print('📊 الثقة:', f\"{result['confidence']:.0%}\")
    print('🏷️ المصدر:', result['source'])
else:
    print('❌ لم يتم العثور على حل مناسب')
    "
fi
