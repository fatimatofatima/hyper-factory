#!/bin/bash
echo "🧪 بدء اختبار أداء Debug Expert المحسن..."

# اختبار على مجموعة من الأخطاء
python3 -c "
from tools.hf_debug_expert_enhanced import EnhancedDebugExpert
import time

expert = EnhancedDebugExpert()

test_cases = [
    {
        'error': 'ModuleNotFoundError: No module named pandas',
        'expected_category': 'import_error'
    },
    {
        'error': 'SyntaxError: invalid syntax near line 5',
        'expected_category': 'syntax_error' 
    },
    {
        'error': 'NameError: name calculate_total is not defined',
        'expected_category': 'name_error'
    },
    {
        'error': 'FileNotFoundError: [Errno 2] No such file or directory: config.yaml',
        'expected_category': 'file_error'
    },
    {
        'error': 'IndexError: list index out of range',
        'expected_category': 'index_error'
    }
]

print('🚀 يختبر Debug Expert المحسن...')
print('=' * 50)

success_count = 0
total_cases = len(test_cases)
start_time = time.time()

for i, test_case in enumerate(test_cases, 1):
    print(f'\\n🔍 الاختبار {i}/{total_cases}: {test_case[\"error\"]}')
    
    result = expert.analyze_error(test_case['error'])
    
    if result and result.get('confidence', 0) > 0.7:
        success_count += 1
        print(f'✅ نجح - الثقة: {result[\"confidence\"]:.0%}')
        print(f'💡 الحل: {result[\"solution\"]}')
    else:
        print(f'❌ فشل - الثقة: {result.get(\"confidence\", 0):.0%}')

end_time = time.time()
total_time = end_time - start_time

success_rate = (success_count / total_cases) * 100
avg_time = total_time / total_cases

print(f'\\n📊 نتائج الاختبار:')
print(f'   ✅ الحالات الناجحة: {success_count}/{total_cases}')
print(f'   📈 معدل النجاح: {success_rate:.1f}%')
print(f'   ⏱️ متوسط وقت التحليل: {avg_time:.2f} ثانية')
print(f'   🎯 الأداء المتوقع: 85%+')

if success_rate >= 80:
    print('   🎉 Debug Expert المحسن يعمل بمستوى ممتاز!')
else:
    print('   ⚠️ يحتاج إلى مزيد من التدريب')
"

echo "🎯 اكتمل اختبار الأداء"
