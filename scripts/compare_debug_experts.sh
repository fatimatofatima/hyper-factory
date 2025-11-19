#!/bin/bash
echo "🧪 مقارنة أداء Debug Expert vs Knowledge-Enhanced Debug Expert"
echo "=" * 60

# اختبارات متنوعة
TEST_CASES=(
    "ModuleNotFoundError: No module named 'pandas'"
    "SyntaxError: invalid syntax"
    "NameError: name 'x' is not defined" 
    "TypeError: unsupported operand type(s) for +: 'int' and 'str'"
    "FileNotFoundError: [Errno 2] No such file or directory: 'data.csv'"
    "IndexError: list index out of range"
    "KeyError: 'username'"
    "AttributeError: 'str' object has no attribute 'append'"
    "ValueError: invalid literal for int() with base 10: 'abc'"
    "IndentationError: expected an indented block"
)

echo "🔍 يختبر الإصدار الأصلي..."
python3 -c "
from tools.hf_debug_expert_enhanced import EnhancedDebugExpert
import time

expert = EnhancedDebugExpert()
success_count_old = 0
total_cases = ${#TEST_CASES[@]}
start_time = time.time()

for error in ${TEST_CASES[@]@Q}; do
    result = expert.analyze_error(error)
    if result and result.get('confidence', 0) > 0.7:
        success_count_old += 1
done

end_time = time.time()
old_time = end_time - start_time
old_success_rate = (success_count_old / total_cases) * 100
"

echo "🔍 يختبر الإصدار المدعوم بالمعرفة..."
python3 -c "
from tools.hf_knowledge_debug_expert import KnowledgeDebugExpert
import time

expert = KnowledgeDebugExpert() 
success_count_new = 0
total_cases = ${#TEST_CASES[@]}
start_time = time.time()

for error in ${TEST_CASES[@]@Q}; do
    result = expert.analyze_error_with_knowledge(error)
    if result and result.get('confidence', 0) > 0.7:
        success_count_new += 1
done

end_time = time.time()
new_time = end_time - start_time
new_success_rate = (success_count_new / total_cases) * 100
"

echo ""
echo "📊 نتائج المقارنة:"
echo "   🔧 الإصدار الأصلي:"
echo "      ✅ النجاح: $success_count_old/${#TEST_CASES[@]} ($old_success_rate%)"
echo "      ⏱️ الوقت: ${old_time%.2f} ثانية"
echo ""
echo "   🧠 الإصدار المدعوم بالمعرفة:"
echo "      ✅ النجاح: $success_count_new/${#TEST_CASES[@]} ($new_success_rate%)" 
echo "      ⏱️ الوقت: ${new_time%.2f} ثانية"
echo ""
echo "   📈 التحسن:"
improvement_rate=$(echo "scale=2; ($new_success_rate - $old_success_rate)" | bc)
time_improvement=$(echo "scale=2; (($old_time - $new_time) / $old_time) * 100" | bc)
echo "      🎯 تحسن النجاح: +${improvement_rate}%"
echo "      ⚡ تحسن السرعة: ${time_improvement}%"

if (( $(echo "$improvement_rate > 10" | bc -l) )); then
    echo "      🎉 تحسن كبير في الأداء!"
else
    echo "      ⚠️ يحتاج إلى مزيد من التحسين"
fi
