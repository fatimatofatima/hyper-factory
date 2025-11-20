#!/bin/bash

echo "🔍 Hyper Factory - فحص شامل وتدقيق تفصيلي"
echo "=========================================="
echo "⏰ $(date)"
echo "📍 $(pwd)"
echo ""

# الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_section() {
    echo -e ""
    echo -e "${BLUE}==================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==================================================${NC}"
}

print_status() {
    local status="$1"
    local message="$2"
    
    case "$status" in
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "WARNING") echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "ERROR") echo -e "${RED}❌ $message${NC}" ;;
        "INFO") echo -e "${CYAN}ℹ️  $message${NC}" ;;
    esac
}

check_component() {
    local name="$1"
    local path="$2"
    local check_type="$3"
    
    echo -e "${CYAN}🔍 فحص: $name${NC}"
    echo -e "   📁 المسار: $path"
    
    case "$check_type" in
        "dir_exists")
            if [ -d "$path" ]; then
                if [ "$(ls -A "$path" 2>/dev/null)" ]; then
                    print_status "SUCCESS" "المجلد موجود وغير فارغ"
                    return 0
                else
                    print_status "WARNING" "المجلد موجود لكن فارغ"
                    return 1
                fi
            else
                print_status "ERROR" "المجلد غير موجود"
                return 2
            fi
            ;;
        "file_exists")
            if [ -f "$path" ]; then
                print_status "SUCCESS" "الملف موجود"
                return 0
            else
                print_status "ERROR" "الملف غير موجود"
                return 2
            fi
            ;;
        "command_exists")
            if command -v "$path" &> /dev/null; then
                print_status "SUCCESS" "الأمر متوفر"
                return 0
            else
                print_status "ERROR" "الأمر غير متوفر"
                return 2
            fi
            ;;
    esac
    echo ""
}

# بدء الفحص الشامل
print_section "1. فحص البنية الأساسية والتكوين"

check_component "ملف تكوين العوامل" "config/agents.yaml" "file_exists"
if [ -f "config/agents.yaml" ]; then
    agent_count=$(grep -c "enabled: true" config/agents.yaml 2>/dev/null || echo "0")
    echo -e "   📊 عدد العوامل المفعلة: $agent_count"
fi

check_component "هيكل العوامل" "agents/" "dir_exists"
check_component "الذاكرة والذكاء الاصطناعي" "ai/" "dir_exists"
check_component "قاعدة البيانات والمعرفة" "data/" "dir_exists"
check_component "التقارير" "reports/" "dir_exists"

print_section "2. فحص العوامل الأساسية (Basic Pipeline)"

basic_agents=("ingestor_basic" "processor_basic" "analyzer_basic" "reporter_basic")
for agent in "${basic_agents[@]}"; do
    check_component "عامل $agent" "agents/${agent}.py" "file_exists"
done

print_section "3. فحص العوامل المتقدمة (Advanced Agents)"

advanced_agents=("debug_expert" "system_architect" "technical_coach" "knowledge_spider")
for agent in "${advanced_agents[@]}"; do
    # فحص سكريبت التشغيل
    check_component "سكريبت $agent" "hf_run_${agent}.sh" "file_exists"
    # فحص أداة البايثون
    check_component "أداة $agent" "tools/hf_${agent}.py" "file_exists"
    # فحص مجلد العامل (إن وجد)
    check_component "مجلد $agent" "agents/${agent}/" "dir_exists"
done

print_section "4. فحص أنظمة التعلم والذكاء"

learning_systems=("offline_learner" "smart_worker" "quality_worker")
for system in "${learning_systems[@]}"; do
    check_component "نظام $system" "hf_run_${system}.sh" "file_exists"
    check_component "أداة $system" "tools/hf_${system}.py" "file_exists"
done

print_section "5. فحص البنية التحتية المتقدمة"

check_component "مصنع البيانات" "data_lakehouse/" "dir_exists"
if [ -d "data_lakehouse" ]; then
    echo -e "   📊 محتويات data_lakehouse:"
    find data_lakehouse -maxdepth 2 -type d 2>/dev/null | head -10 | while read dir; do
        echo -e "      📁 $dir"
    done
fi

check_component "المصانع" "factories/" "dir_exists"
check_component "المكدس التقني" "stack/" "dir_exists"

print_section "6. فحص قاعدة المعرفة والذاكرة"

# فحص قاعدة المعرفة
if [ -f "data/knowledge/knowledge.db" ]; then
    print_status "SUCCESS" "قاعدة المعرفة موجودة"
    # عد سجلات العوامل
    agent_records=$(sqlite3 data/knowledge/knowledge.db "SELECT COUNT(*) FROM knowledge_items WHERE item_type LIKE '%agent%';" 2>/dev/null || echo "0")
    echo -e "   📊 سجلات العوامل في knowledge.db: $agent_records"
    
    # عد إجمالي السجلات
    total_records=$(sqlite3 data/knowledge/knowledge.db "SELECT COUNT(*) FROM knowledge_items;" 2>/dev/null || echo "0")
    echo -e "   📊 إجمالي السجلات في knowledge.db: $total_records"
else
    print_status "ERROR" "قاعدة المعرفة غير موجودة"
fi

# فحص الذاكرة
check_component "ذاكرة النظام" "ai/memory/" "dir_exists"
if [ -d "ai/memory" ]; then
    memory_files=$(find ai/memory -name "*.json" -o -name "*.txt" 2>/dev/null | wc -l)
    echo -e "   📊 عدد ملفات الذاكرة: $memory_files"
    
    # فحص الملفات المهمة
    important_files=("quality_status.json" "smart_actions.json" "messages.jsonl")
    for file in "${important_files[@]}"; do
        if [ -f "ai/memory/$file" ]; then
            echo -e "   ${GREEN}✅ $file موجود${NC}"
        else
            echo -e "   ${YELLOW}⚠️  $file غير موجود${NC}"
        fi
    done
fi

print_section "7. فحص السكريبتات والتشغيل"

# فحص السكريبتات الرئيسية
main_scripts=("hf_master_dashboard.sh" "hf_quick_dashboard.sh" "hf_ops_master.sh" "run_basic_cycle.sh")
for script in "${main_scripts[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        print_status "SUCCESS" "$script (قابل للتنفيذ)"
    elif [ -f "$script" ]; then
        print_status "WARNING" "$script (موجود لكن غير قابل للتنفيذ)"
    else
        print_status "ERROR" "$script (غير موجود)"
    fi
done

print_section "8. فحص العمليات النشطة والتكامل"

echo -e "${CYAN}🔍 العمليات النشطة المرتبطة بـ Hyper Factory:${NC}"
ps aux | grep -E "(hyper-factory|hf_|smartfriend)" | grep -v grep | head -10 | while read process; do
    echo -e "   🖥️  $process"
done

print_section "9. إحصائيات شاملة"

# عد الملفات والتقارير
total_scripts=$(find . -name "*.sh" -type f | grep -v ".git" | wc -l)
total_python=$(find . -name "*.py" -type f | grep -v ".git" | wc -l)
total_reports=$(find reports -name "*.md" -o -name "*.txt" 2>/dev/null | wc -l)
total_agents=$(find agents -name "*.py" -o -name "*.sh" 2>/dev/null | wc -l)

echo -e "${CYAN}📊 الإحصائيات النهائية:${NC}"
echo -e "   📜 عدد السكريبتات: $total_scripts"
echo -e "   🐍 عدد ملفات البايثون: $total_python"
echo -e "   📋 عدد التقارير: $total_reports"
echo -e "   🤖 عدد ملفات العوامل: $total_agents"

print_section "10. التقييم النهائي"

# تحليل النتائج
echo -e "${CYAN}🎯 ملخص الحالة:${NC}"

if [ $total_scripts -gt 15 ] && [ $total_python -gt 10 ] && [ $total_reports -gt 50 ]; then
    print_status "SUCCESS" "النظام متطور ومتكامل"
elif [ $total_scripts -gt 10 ] && [ $total_python -gt 5 ] && [ $total_reports -gt 20 ]; then
    print_status "WARNING" "النظام يعمل لكن يحتاج تطوير"
else
    print_status "ERROR" "النظام أساسي ويحتاج عمل كثير"
fi

# توصيات
echo -e ""
echo -e "${CYAN}💡 التوصيات:${NC}"
if [ ! -d "agents/debug_expert" ]; then
    echo -e "   📌 إنشاء هيكل مجلدات للعوامل المتقدمة"
fi
if [ ! -f "requirements.txt" ]; then
    echo -e "   📌 إنشاء ملف المتطلبات (requirements.txt)"
fi
if [ ! -d "feedback" ]; then
    echo -e "   📌 إضافة نظام التعليقات (feedback/)"
fi

echo ""
echo "✅ اكتمل الفحص الشامل - $(date)"
