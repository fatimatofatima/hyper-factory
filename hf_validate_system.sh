#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Hyper Factory - الفحص الشامل للنظام"
echo "========================================"
echo "⏰ $(date)"
echo "📍 $(pwd)"
echo ""

# 1. فحص البنية الأساسية
echo "📁 1. فحص هيكل المجلدات والملفات"
echo "--------------------------------"

check_dir() {
    local dir="$1"
    local desc="$2"
    if [[ -d "$dir" ]]; then
        if [[ $(ls -A "$dir" 2>/dev/null) ]]; then
            echo "✅ $desc - موجود وغير فارغ"
            return 0
        else
            echo "⚠️  $desc - موجود لكن فارغ"
            return 1
        fi
    else
        echo "❌ $desc - مفقود"
        return 2
    fi
}

check_file() {
    local file="$1"
    local desc="$2"
    if [[ -f "$file" ]]; then
        if [[ -s "$file" ]]; then
            echo "✅ $desc - موجود وغير فارغ"
            return 0
        else
            echo "⚠️  $desc - موجود لكن فارغ"
            return 1
        fi
    else
        echo "❌ $desc - مفقود"
        return 2
    fi
}

# فحص المجلدات الأساسية
check_dir "agents" "مجلد العوامل"
check_dir "config" "مجلد التكوين"
check_dir "ai" "مجلد الذكاء الاصطناعي"
check_dir "reports" "مجلد التقارير"
check_dir "data" "مجلد البيانات"
check_dir "scripts" "مجلد السكريبتات"

echo ""

# 2. فحص العوامل المتقدمة
echo "🤖 2. فحص العوامل المتقدمة"
echo "--------------------------"

declare -A agents=(
    ["debug_expert"]="خبير التصحيح"
    ["system_architect"]="المهندس المعماري"
    ["technical_coach"]="المدرب التقني"
    ["knowledge_spider"]="زاحف المعرفة"
)

for agent in "${!agents[@]}"; do
    echo "🔍 فحص عامل: ${agents[$agent]}"
    
    # فحص مجلد العامل
    check_dir "agents/$agent" "   - مجلد العامل"
    
    # فحص سكريبت التشغيل
    check_file "hf_run_${agent}.sh" "   - سكريبت التشغيل"
    
    # فحص الأداة البايثون
    check_file "tools/hf_${agent}.py" "   - أداة البايثون"
    
    # فحص التكوين في agents.yaml
    if grep -q "$agent" config/agents.yaml 2>/dev/null; then
        echo "✅   - مضاف في agents.yaml"
    else
        echo "❌   - مفقود من agents.yaml"
    fi
    echo ""
done

# 3. فحص أنظمة التعلم والذاكرة
echo "🧠 3. فحص أنظمة التعلم والذاكرة"
echo "-------------------------------"

check_file "ai/memory/quality_status.json" "حالة الجودة"
check_file "ai/memory/smart_actions.json" "الإجراءات الذكية"
check_file "ai/memory/messages.jsonl" "سجل المحادثات"
check_file "ai/patterns/patterns_index.json" "فهرس الأنماط"

# فحص قاعدة المعرفة
if [[ -f "data/knowledge/knowledge.db" ]] || [[ -d "knowledge" ]]; then
    echo "✅ قاعدة المعرفة - موجودة"
else
    echo "❌ قاعدة المعرفة - مفقودة"
fi

echo ""

# 4. فحص السكريبتات التشغيلية
echo "⚙️  4. فحص السكريبتات التشغيلية"
echo "-----------------------------"

declare -A scripts=(
    ["hf_master_dashboard.sh"]="لوحة التحكم الرئيسية"
    ["hf_quick_dashboard.sh"]="لوحة التحكم السريعة"
    ["hf_ops_master.sh"]="مدير العمليات"
    ["hf_comprehensive_audit.sh"]="الفحص الشامل"
    ["run_basic_cycle.sh"]="دورة المصنع الأساسية"
)

for script in "${!scripts[@]}"; do
    if [[ -f "$script" ]] && [[ -x "$script" ]]; then
        echo "✅ ${scripts[$script]} - قابل للتنفيذ"
    else
        echo "❌ ${scripts[$script]} - مفقود أو غير قابل للتنفيذ"
    fi
done

echo ""

# 5. فحص التكوينات
echo "📋 5. فحص ملفات التكوين"
echo "-----------------------"

check_file "config/agents.yaml" "تكوين العوامل"
check_file "config/factory.yaml" "تكوين المصنع"
check_file "config/orchestrator.yaml" "تكوين المنظم"
check_file "config/roles.json" "تكوين الأدوار"

echo ""

# 6. فحص النظام النشط
echo "🚀 6. فحص النظام النشط"
echo "----------------------"

# فحص العمليات النشطة
echo "🔍 العمليات النشطة:"
pgrep -f "hyper-factory" && echo "✅ عمليات Hyper Factory نشطة" || echo "⚠️  لا توجد عمليات نشطة"

# فحص الذاكرة والتخزين
echo ""
echo "💾 موارد النظام:"
free -h | grep Mem | awk '{print "   الذاكرة الحرة: " $4}'
df -h . | awk 'NR==2 {print "   المساحة الحرة: " $4}'

echo ""

# 7. فحص الإخراج والتقارير
echo "📊 7. فحص التقارير والإخراج"
echo "---------------------------"

# عد التقارير الحديثة
recent_reports=$(find reports -name "*.md" -o -name "*.txt" -mtime -1 2>/dev/null | wc -l)
echo "   📈 التقارير اليومية: $recent_reports"

# عد ملفات الذاكرة
memory_files=$(find ai/memory -type f 2>/dev/null | wc -l)
echo "   🧠 ملفات الذاكرة: $memory_files"

# فحص آخر تقرير مالك
latest_owner=$(ls -t reports/ai/OWNER_*.md 2>/dev/null | head -1)
if [[ -n "$latest_owner" ]]; then
    echo "   👤 آخر تقرير مالك: $(basename $latest_owner)"
else
    echo "   ❌ لا توجد تقارير مالك حديثة"
fi

echo ""

# 8. ملخص الحالة
echo "🎯 8. ملخص الحالة النهائي"
echo "------------------------"

total_checks=0
passed_checks=0

# حساب النتائج (مبسط)
count_results() {
    local output="$1"
    passed=$(echo "$output" | grep -c "✅" || true)
    warning=$(echo "$output" | grep -c "⚠️" || true)
    failed=$(echo "$output" | grep -c "❌" || true)
    
    total=$((passed + warning + failed))
    
    echo "   ✅ ناجح: $passed"
    echo "   ⚠️  تحذير: $warning" 
    echo "   ❌ فاشل: $failed"
    
    if [[ $failed -eq 0 ]] && [[ $warning -eq 0 ]]; then
        echo "   🎉 الحالة: ممتاز - النظام كامل وجاهز"
    elif [[ $failed -eq 0 ]]; then
        echo "   👍 الحالة: جيد - يحتاج تحسينات طفيفة"
    else
        echo "   🚨 الحالة: يحتاج اهتمام - هناك مكونات مفقودة"
    fi
}

# جمع النتائج من الفحص
results=$(grep -E "✅|⚠️|❌" "$0" | head -50)
count_results "$results"

echo ""
echo "========================================"
echo "✅ اكتمل الفحص الشامل - $(date)"
