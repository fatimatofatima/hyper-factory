#!/bin/bash

echo "🕵️ بدء البحث الشامل عن جميع العمال في النظام..."
echo "=================================================="
echo "⏰ الوقت: $(date)"
echo "📍 المسار: $(pwd)"
echo ""

# الألوان للتنسيق
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# دالة لعرض الحالة
print_status() {
    local type=$1
    local name=$2
    local status=$3
    local details=$4
    
    case $status in
        "ACTIVE") echo -e "${GREEN}✅ [$type] $name${NC} - $details" ;;
        "INACTIVE") echo -e "${YELLOW}🔄 [$type] $name${NC} - $details" ;;
        "MISSING") echo -e "${RED}❌ [$type] $name${NC} - $details" ;;
        "PARTIAL") echo -e "${BLUE}⚠️  [$type] $name${NC} - $details" ;;
        "CONFIGURED") echo -e "${PURPLE}📋 [$type] $name${NC} - $details" ;;
        "RUNNING") echo -e "${CYAN}🚀 [$type] $name${NC} - $details" ;;
    esac
}

# دالة للبحث في الملفات عن أسماء العمال
find_agent_references() {
    local agent_name=$1
    echo -e "\n${CYAN}🔍 تتبع العامل: $agent_name${NC}"
    
    # البحث في جميع الملفات
    echo "📁 البحث في الملفات النصية:"
    grep -r --include="*.sh" --include="*.py" --include="*.yaml" --include="*.yml" --include="*.md" --include="*.txt" \
         -l "$agent_name" . 2>/dev/null | while read file; do
        echo "   📄 $file"
    done
    
    # البحث في العمليات النشطة
    echo "🔄 البحث في العمليات النشطة:"
    if pgrep -f "$agent_name" > /dev/null; then
        echo "   🟢 عامل نشط في الذاكرة"
        ps aux | grep "$agent_name" | grep -v grep | head -2
    else
        echo "   🔴 غير نشط في الذاكرة"
    fi
}

# ============================================================================
# 1. البحث عن العمال في ملفات التكوين
# ============================================================================

echo "${GREEN}1. 🔧 العمال في ملفات التكوين${NC}"
echo "----------------------------------------"

# فحص config/agents.yaml
if [ -f "config/agents.yaml" ]; then
    echo -e "\n${BLUE}📋 العمال في config/agents.yaml:${NC}"
    
    # استخراج العمال الأساسية
    basic_agents=$(grep -A5 "basic_agents:" config/agents.yaml | grep "id:" | cut -d'"' -f2)
    for agent in $basic_agents; do
        enabled=$(grep -A10 "id:.*$agent" config/agents.yaml | grep "enabled:" | grep -o "true\|false")
        if [ "$enabled" = "true" ]; then
            print_status "BASIC" "$agent" "ACTIVE" "مفعل في التكوين"
        else
            print_status "BASIC" "$agent" "INACTIVE" "معطل في التكوين"
        fi
    done
    
    # استخراج العمال المتقدمة
    advanced_agents=$(grep -A5 "advanced_agents:" config/agents.yaml | grep "id:" | cut -d'"' -f2)
    for agent in $advanced_agents; do
        enabled=$(grep -A10 "id:.*$agent" config/agents.yaml | grep "enabled:" | grep -o "true\|false")
        if [ "$enabled" = "true" ]; then
            print_status "ADVANCED" "$agent" "ACTIVE" "مفعل في التكوين"
        else
            print_status "ADVANCED" "$agent" "INACTIVE" "معطل في التكوين"
        fi
    done
else
    echo -e "${RED}❌ ملف config/agents.yaml غير موجود${NC}"
fi

# ============================================================================
# 2. البحث عن سكريبتات التشغيل
# ============================================================================

echo -e "\n${GREEN}2. 🚀 سكريبتات تشغيل العمال${NC}"
echo "----------------------------------------"

# البحث عن جميع سكريبتات hf_run_*
run_scripts=$(find . -name "hf_run_*.sh" -o -name "run_*.sh" | sort)

if [ -n "$run_scripts" ]; then
    for script in $run_scripts; do
        script_name=$(basename "$script")
        # استخراج اسم العامل من اسم السكريبت
        agent_name=$(echo "$script_name" | sed 's/^hf_run_//' | sed 's/^run_//' | sed 's/\.sh$//')
        
        if [ -x "$script" ]; then
            print_status "SCRIPT" "$agent_name" "RUNNING" "$script"
        else
            print_status "SCRIPT" "$agent_name" "INACTIVE" "$script (غير قابل للتنفيذ)"
        fi
    done
else
    echo -e "${YELLOW}⚠️  لم يتم العثور على سكريبتات تشغيل${NC}"
fi

# ============================================================================
# 3. البحث في مجلد agents
# ============================================================================

echo -e "\n${GREEN}3. 📁 مجلدات العمال${NC}"
echo "----------------------------------------"

if [ -d "agents" ]; then
    agent_dirs=$(find agents -type d -mindepth 1 -maxdepth 1 | sort)
    
    if [ -n "$agent_dirs" ]; then
        for dir in $agent_dirs; do
            agent_name=$(basename "$dir")
            file_count=$(find "$dir" -type f | wc -l)
            
            if [ $file_count -gt 0 ]; then
                print_status "DIR" "$agent_name" "ACTIVE" "$dir (${file_count} ملف)"
            else
                print_status "DIR" "$agent_name" "EMPTY" "$dir (فارغ)"
            fi
        done
    else
        echo -e "${YELLOW}⚠️  مجلد agents فارغ${NC}"
    fi
else
    echo -e "${RED}❌ مجلد agents غير موجود${NC}"
fi

# ============================================================================
# 4. البحث في العمليات النشطة
# ============================================================================

echo -e "\n${GREEN}4. 🔥 العمال النشطين في الذاكرة${NC}"
echo "----------------------------------------"

# البحث عن عمليات Python مرتبطة بالعمال
python_processes=$(ps aux | grep -v grep | grep python | grep -E "agent|run|hf_" || true)

if [ -n "$python_processes" ]; then
    echo "🐍 عمليات Python نشطة:"
    echo "$python_processes" | while read process; do
        pid=$(echo $process | awk '{print $2}')
        cmd=$(echo $process | awk '{$1=$2=$3=$4=$5=$6=$7=$8=$9=""; print $0}')
        # استخراج اسم العامل من الأمر
        agent_name=$(echo "$cmd" | grep -o "agent_[a-zA-Z_]*\|run_[a-zA-Z_]*\|hf_[a-zA-Z_]*" | head -1)
        if [ -n "$agent_name" ]; then
            print_status "PROCESS" "$agent_name" "RUNNING" "PID: $pid - $cmd"
        fi
    done
else
    echo -e "${YELLOW}⚠️  لا توجد عمليات Python نشطة${NC}"
fi

# البحث عن عمليات سكريبتات shell
shell_processes=$(ps aux | grep -v grep | grep -E "hf_run_|run_.*\.sh" || true)

if [ -n "$shell_processes" ]; then
    echo "🐚 عمليات Shell نشطة:"
    echo "$shell_processes" | while read process; do
        pid=$(echo $process | awk '{print $2}')
        cmd=$(echo $process | awk '{$1=$2=$3=$4=$5=$6=$7=$8=$9=""; print $0}')
        agent_name=$(echo "$cmd" | grep -o "hf_run_[a-zA-Z_]*\|run_[a-zA-Z_]*" | head -1)
        if [ -n "$agent_name" ]; then
            print_status "PROCESS" "$agent_name" "RUNNING" "PID: $pid"
        fi
    done
fi

# ============================================================================
# 5. البحث في السجلات والذاكرة
# ============================================================================

echo -e "\n${GREEN}5. 📊 السجلات والذاكرة${NC}"
echo "----------------------------------------"

# فحص سجلات الذاكرة
if [ -d "ai/memory" ]; then
    memory_files=$(find ai/memory -name "*.json" -o -name "*.jsonl" -o -name "*.txt" | head -5)
    
    echo "🧠 ملفات الذاكرة:"
    for file in $memory_files; do
        file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")
        # البحث عن إشارات للعمال في الملف
        agent_refs=$(grep -o "agent_[a-zA-Z_]*\|debug_expert\|system_architect" "$file" 2>/dev/null | sort | uniq | head -3 | tr '\n' ' ')
        
        if [ -n "$agent_refs" ]; then
            echo "   📄 $file (${file_size} bytes) - 👥: $agent_refs"
        else
            echo "   📄 $file (${file_size} bytes)"
        fi
    done
else
    echo -e "${YELLOW}⚠️  مجلد ai/memory غير موجود${NC}"
fi

# ============================================================================
# 6. البحث في قاعدة المعرفة
# ============================================================================

echo -e "\n${GREEN}6. 🧠 قاعدة المعرفة${NC}"
echo "----------------------------------------"

# فحص قاعدة المعرفة
if [ -f "data/knowledge/knowledge.db" ]; then
    echo "📚 فحص قاعدة المعرفة..."
    # استخدام sqlite3 للبحث عن العمال
    if command -v sqlite3 >/dev/null 2>&1; then
        agent_records=$(sqlite3 data/knowledge/knowledge.db "SELECT type, name FROM knowledge_items WHERE type LIKE '%agent%' OR name LIKE '%agent%' LIMIT 10;" 2>/dev/null || true)
        
        if [ -n "$agent_records" ]; then
            echo "$agent_records" | while IFS='|' read type name; do
                print_status "KNOWLEDGE" "$name" "CONFIGURED" "نوع: $type"
            done
        else
            echo -e "${YELLOW}⚠️  لا توجد سجلات للعمال في قاعدة المعرفة${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  sqlite3 غير مثبت لفحص قاعدة البيانات${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  قاعدة المعرفة غير موجودة${NC}"
fi

# ============================================================================
# 7. الإحصائيات النهائية
# ============================================================================

echo -e "\n${GREEN}7. 📈 إحصائيات شاملة${NC}"
echo "----------------------------------------"

# عد العمال بأنواعها
total_config_agents=$(($(echo "$basic_agents" | wc -w) + $(echo "$advanced_agents" | wc -w)))
total_scripts=$(echo "$run_scripts" | wc -w)
total_dirs=$(echo "$agent_dirs" | wc -w)
total_processes=$(($(echo "$python_processes" | wc -l) + $(echo "$shell_processes" | wc -l)))

echo "📊 إحصائيات العمال:"
echo "   🔧 العمال في التكوين: $total_config_agents"
echo "   🚀 سكريبتات التشغيل: $total_scripts"
echo "   📁 مجلدات العمال: $total_dirs"
echo "   🔥 العمليات النشطة: $total_processes"

# تحديد الحالة العامة
if [ $total_config_agents -gt 0 ] && [ $total_scripts -gt 0 ]; then
    echo -e "\n${GREEN}🎉 النظام يحتوي على بنية عمال جيدة!${NC}"
elif [ $total_config_agents -eq 0 ] && [ $total_scripts -gt 0 ]; then
    echo -e "\n${YELLOW}⚠️  العمال موجودة كسكريبتات ولكن تحتاج تكوين${NC}"
else
    echo -e "\n${RED}❌ النظام يحتاج إلى إعداد العمال${NC}"
fi

# ============================================================================
# 8. البحث المتقدم عن عمال محددة
# ============================================================================

echo -e "\n${GREEN}8. 🔍 البحث المتقدم عن عمال محددة${NC}"
echo "----------------------------------------"

# قائمة العمال المهمة للبحث عنها
important_agents=("debug_expert" "system_architect" "technical_coach" "knowledge_spider" 
                  "ingestor_basic" "processor_basic" "analyzer_basic" "reporter_basic")

for agent in "${important_agents[@]}"; do
    found_in_config=false
    found_in_scripts=false
    found_in_processes=false
    
    # البحث في التكوين
    if grep -q "$agent" config/agents.yaml 2>/dev/null; then
        found_in_config=true
    fi
    
    # البحث في السكريبتات
    if find . -name "*$agent*" -type f 2>/dev/null | grep -q .; then
        found_in_scripts=true
    fi
    
    # البحث في العمليات
    if ps aux | grep -v grep | grep -q "$agent"; then
        found_in_processes=true
    fi
    
    # عرض النتيجة
    if [ "$found_in_config" = true ] || [ "$found_in_scripts" = true ] || [ "$found_in_processes" = true ]; then
        status_details=""
        [ "$found_in_config" = true ] && status_details+="📋 "
        [ "$found_in_scripts" = true ] && status_details+="🚀 "
        [ "$found_in_processes" = true ] && status_details+="🔥 "
        
        print_status "SEARCH" "$agent" "ACTIVE" "$status_details"
    else
        print_status "SEARCH" "$agent" "MISSING" "غير موجود في النظام"
    fi
done

echo -e "\n${GREEN}🔍 البحث الشامل اكتمل!${NC}"
echo "=================================================="

# عرض اقتراح للخطوة التالية
echo -e "\n${CYAN}💡 اقتراح للخطوة التالية:${NC}"
echo "لتشغيل عامل محدد، استخدم: ./hf_run_<اسم_العامل>.sh"
echo "لعرض تفاصيل عامل، استخدم: ./hf_find_all_agents.sh && find_agent_references <اسم_العامل>"

