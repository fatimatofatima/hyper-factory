#!/usr/bin/env bash
set -euo pipefail

echo "🧠 تشغيل محرك التعلم الآلي التلقائي..."
echo "======================================"

# 1. تحليل الأنماط من السجلات
analyze_patterns() {
    echo "🔍 تحليل أنماط الأخطاء والنجاحات..."
    python3 -c "
import json
from collections import Counter

# تحليل messages.jsonl
try:
    with open('ai/memory/messages.jsonl', 'r') as f:
        messages = [json.loads(line) for line in f if line.strip()]
    
    # تحليل الأنماط
    error_patterns = Counter()
    success_patterns = Counter()
    
    for msg in messages[-100:]:  # آخر 100 رسالة
        content = msg.get('content', '').lower()
        if 'error' in content or 'traceback' in content:
            error_patterns['debug_cases'] += 1
        if 'مشروع' in content or 'تصميم' in content:
            success_patterns['architecture_designs'] += 1
        if 'تعلم' in content or 'تدريب' in content:
            success_patterns['coaching_sessions'] += 1
    
    # حفظ التحليل
    patterns_data = {
        'error_patterns': dict(error_patterns),
        'success_patterns': dict(success_patterns),
        'total_sessions': len(messages),
        'analysis_date': '$(date)'
    }
    
    with open('ai/patterns/learning_patterns.json', 'w') as f:
        json.dump(patterns_data, f, ensure_ascii=False, indent=2)
    
    print('✅ تم تحليل الأنماط:', patterns_data)
    
except Exception as e:
    print('❌ خطأ في تحليل الأنماط:', e)
"
}

# 2. تحسين البرومبتات بناءً على التعلم
optimize_prompts() {
    echo "🔄 تحسين البرومبتات بناءً على الأنماط..."
    
    if [[ -f "ai/patterns/learning_patterns.json" ]]; then
        python3 -c "
import json
import yaml

# قراءة الأنماط
with open('ai/patterns/learning_patterns.json', 'r') as f:
    patterns = json.load(f)

# تحسين برومبت Debug Expert
if patterns.get('error_patterns', {}).get('debug_cases', 0) > 10:
    print('🎯 تحسين Debug Expert - زيادة التركيز على الأخطاء الشائعة')
    
    with open('ai/prompts/agent_debug_expert.md', 'a') as f:
        f.write('\n\n# 🎯 تحسين تلقائي بناءً على التعلم')
        f.write('\n# تم اكتشاف ' + str(patterns['error_patterns']['debug_cases']) + ' حالة تصحيح')
        f.write('\n# ركز على: تحليل Traceback، إصلاح الأخطاء المتكررة')

print('✅ تم تحسين البرومبتات بناءً على التعلم')
"
    fi
}

# 3. تحديث قاعدة المعرفة تلقائياً
update_knowledge_auto() {
    echo "📚 تحديث قاعدة المعرفة تلقائياً..."
    ./hf_run_knowledge_spider.sh --auto-update
}

# 4. تدريب النماذج على البيانات الجديدة
train_models() {
    echo "🏋️ تدريب النماذج على البيانات المتراكمة..."
    
    if [[ -f "ai/datasets/messages.jsonl" ]]; then
        python3 -c "
import json

# تحضير بيانات التدريب
with open('ai/datasets/messages.jsonl', 'r') as f:
    training_data = []
    for line in f:
        if line.strip():
            msg = json.loads(line)
            if msg.get('content'):
                training_data.append({
                    'text': msg['content'],
                    'timestamp': msg.get('timestamp', '')
                })

# حفظ بيانات التدريب
if training_data:
    with open('ai/datasets/training_dataset.json', 'w') as f:
        json.dump(training_data, f, ensure_ascii=False, indent=2)
    print(f'✅ تم إعداد {len(training_data)} عينة للتدريب')
else:
    print('ℹ️ لا توجد بيانات كافية للتدريب')
"
    fi
}

# التشغيل الرئيسي
main() {
    echo "🚀 بدء دورة التعلم الآلي التلقائي..."
    analyze_patterns
    optimize_prompts
    update_knowledge_auto
    train_models
    echo "🎉 اكتملت دورة التعلم الآلي!"
}

main "$@"
