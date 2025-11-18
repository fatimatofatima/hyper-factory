#!/bin/bash

echo "🏥 ==================================================="
echo "           فحص شامل لنظام Hyper Factory"
echo "=================================================== 🏥"
echo ""

# ألوان للتنسيق
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# دالة للطباعة الملونة
print_status() {
    if [ "$1" = "success" ]; then
        echo -e "${GREEN}✅ $2${NC}"
    elif [ "$1" = "warning" ]; then
        echo -e "${YELLOW}⚠️  $2${NC}"
    elif [ "$1" = "error" ]; then
        echo -e "${RED}❌ $2${NC}"
    elif [ "$1" = "info" ]; then
        echo -e "${BLUE}ℹ️  $2${NC}"
    fi
}

# دالة للتحقق من وجود ملف
check_file() {
    if [ -f "$1" ]; then
        print_status "success" "الملف: $1"
        return 0
    else
        print_status "error" "الملف مفقود: $1"
        return 1
    fi
}

# دالة للتحقق من وجود مجلد
check_dir() {
    if [ -d "$1" ]; then
        print_status "success" "المجلد: $1"
        return 0
    else
        print_status "error" "المجلد مفقود: $1"
        return 1
    fi
}

# دالة لفحص خدمة
check_service() {
    local service_name=$1
    local port=$2
    
    echo ""
    print_status "info" "فحص خدمة: $service_name"
    
    # التحقق من العملية
    if pgrep -f "uvicorn.*$port" > /dev/null; then
        print_status "success" "الخدمة شغالة على المنفذ $port"
        
        # التحقق من الاستجابة
        if curl -s "http://localhost:$port/api/health" > /dev/null; then
            print_status "success" "الخدمة تستجيب للطلبات"
            
            # جلب تفاصيل الصحة
            local health_response=$(curl -s "http://localhost:$port/api/health")
            echo "   📊 حالة الخدمة: $health_response"
        else
            print_status "error" "الخدمة لا تستجيب للطلبات"
        fi
    else
        print_status "error" "الخدمة غير شغالة على المنفذ $port"
    fi
}

# دالة لفحص API endpoint
check_endpoint() {
    local endpoint=$1
    local expected_code=$2
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:9090$endpoint")
    
    if [ "$response" -eq "$expected_code" ]; then
        print_status "success" "Endpoint: $endpoint (HTTP $response)"
        
        # إذا كان 200، نجلب محتوى الرد
        if [ "$response" -eq 200 ]; then
            local content=$(curl -s "http://localhost:9090$endpoint" | head -c 100)
            echo "   📦 محتوى: $content..."
        fi
    else
        print_status "error" "Endpoint: $endpoint (توقع HTTP $expected_code، حصل HTTP $response)"
    fi
}

echo "📁 ========== فحص هيكل الملفات =========="

# فحص المجلدات الأساسية
check_dir "/root/hyper-factory"
check_dir "/root/hyper-factory/apps"
check_dir "/root/hyper-factory/apps/backend_coach"
check_dir "/root/hyper-factory/scripts"
check_dir "/root/hyper-factory/scripts/ai"
check_dir "/root/hyper-factory/scripts/ai/llm"
check_dir "/root/hyper-factory/scripts/config"
check_dir "/root/hyper-factory/ai"
check_dir "/root/hyper-factory/ai/datasets"
check_dir "/root/hyper-factory/ai/datasets/user_skills"
check_dir "/root/hyper-factory/logs"
check_dir "/root/hyper-factory/logs/apps"

# فحص الملفات الأساسية
echo ""
echo "📄 ========== فحص الملفات الأساسية =========="
check_file "/root/hyper-factory/apps/backend_coach/main.py"
check_file "/root/hyper-factory/scripts/ai/skills_manager.py"
check_file "/root/hyper-factory/scripts/ai/llm/llm_orchestrator.py"
check_file "/root/hyper-factory/scripts/config/orchestrator.yaml"
check_file "/root/hyper-factory/scripts/core/ffactory.sh"

# فحص ملفات البيانات
echo ""
echo "💾 ========== فحص ملفات البيانات =========="
check_file "/root/hyper-factory/ai/datasets/user_skills/test_user_001.json" || {
    print_status "warning" "إنشاء ملف بيانات تجريبي..."
    mkdir -p /root/hyper-factory/ai/datasets/user_skills
    cat << 'JSONEOF' > /root/hyper-factory/ai/datasets/user_skills/test_user_001.json
{
  "user_id": "test_user_001",
  "skills": {
    "python_syntax_basics": 75,
    "python_control_flow": 60,
    "python_functions_basics": 45
  },
  "level": "intermediate"
}
JSONEOF
    print_status "success" "تم إنشاء ملف بيانات تجريبي"
}

echo ""
echo "🔧 ========== فحص التبعيات والبيئة =========="

# فحص بايثون والمكتبات
if command -v python3 &> /dev/null; then
    print_status "success" "بايثون 3 مثبت"
    
    # فحص مكتبات FastAPI
    if python3 -c "import fastapi" &> /dev/null; then
        print_status "success" "FastAPI مثبت"
    else
        print_status "error" "FastAPI غير مثبت"
    fi
    
    if python3 -c "import uvicorn" &> /dev/null; then
        print_status "success" "uvicorn مثبت"
    else
        print_status "error" "uvicorn غير مثبت"
    fi
else
    print_status "error" "بايثون 3 غير مثبت"
fi

# فحص الـPython path
echo ""
print_status "info" "فحص مسارات بايثون:"
python3 -c "import sys; print('   🛣️  مسارات النظام:', [p for p in sys.path if 'hyper-factory' in p])"

echo ""
echo "🚀 ========== فحص الخدمات والشبكة =========="

# فحص المنافذ
print_status "info" "فحص المنافذ المشغولة:"
netstat -tulpn | grep 9090 || print_status "warning" "المنفذ 9090 غير مشغول"

# فحص خدمة backend_coach
check_service "backend_coach" "9090"

echo ""
echo "🌐 ========== فحص نقاط API =========="

# فحص نقاط API الأساسية
check_endpoint "/" 200
check_endpoint "/api/health" 200
check_endpoint "/api/skills/state?user_id=test_user_001" 200
check_endpoint "/api/orchestrator/analyze?user_id=test_user_001&message=test" 200

# فحص تحديث المهارات
echo ""
print_status "info" "فحص تحديث المهارات:"
update_response=$(curl -s -X POST "http://localhost:9090/api/skills/update?user_id=test_user_001&skill_id=python_syntax_basics&new_score=80")
if echo "$update_response" | grep -q "python_syntax_basics"; then
    print_status "success" "تحديث المهارات يعمل: $update_response"
else
    print_status "error" "تحديث المهارات فشل: $update_response"
fi

echo ""
echo "🔍 ========== فحص المكونات الداخلية =========="

# فحص المكونات الداخلية
cd /root/hyper-factory

print_status "info" "فحص Skills Manager:"
python3 -c "
import sys
sys.path.insert(0, '/root/hyper-factory')
try:
    from scripts.ai.skills_manager import SkillsManager
    sm = SkillsManager()
    result = sm.get_skills_state('health_check_user')
    print('   ✅ Skills Manager يعمل بنجاح')
    print(f'   📊 نتيجة الاختبار: {result}')
except Exception as e:
    print(f'   ❌ خطأ في Skills Manager: {e}')
"

print_status "info" "فحص LLM Orchestrator:"
python3 -c "
import sys
sys.path.insert(0, '/root/hyper-factory')
try:
    from scripts.ai.llm.llm_orchestrator import LLMOrchestrator
    orch = LLMOrchestrator()
    print('   ✅ LLM Orchestrator يعمل بنجاح')
    # اختبار تحليل رسالة
    try:
        analysis = orch.analyze_message('test_user', 'كيف اتعلم بايثون')
        print(f'   🧠 نتيجة التحليل: {analysis}')
    except Exception as e:
        print(f'   ⚠️  تحليل الرسالة فيه مشكلة: {e}')
except Exception as e:
    print(f'   ❌ خطأ في LLM Orchestrator: {e}')
"

echo ""
echo "📊 ========== فحص الأداء والموارد =========="

# فحص استخدام الذاكرة
print_status "info" "فحص استخدام الموارد:"
ps aux --sort=-%mem | head -n 5 | grep -E "(python|uvicorn)" || print_status "warning" "لا توجد عمليات بايثون نشطة"

# فحص مساحة التخزين
echo ""
print_status "info" "فحص مساحة التخزين:"
du -sh /root/hyper-factory | awk '{print "   💾 حجم المشروع: " $1}'
du -sh /root/hyper-factory/ai/datasets | awk '{print "   🗃️  حجم البيانات: " $1}'

echo ""
echo "🔐 ========== فحص الأذونات =========="

# فحص الأذونات
check_permission() {
    local file=$1
    if [ -w "$file" ]; then
        print_status "success" "صلاحيات كتابة: $file"
    else
        print_status "error" "لا توجد صلاحيات كتابة: $file"
    fi
}

check_permission "/root/hyper-factory"
check_permission "/root/hyper-factory/apps/backend_coach/main.py"
check_permission "/root/hyper-factory/ai/datasets"

echo ""
echo "📝 ========== فحص السجلات =========="

# فحص السجلات
if [ -f "/root/hyper-factory/logs/apps/backend_coach.log" ]; then
    print_status "success" "سجلات التطبيق موجودة"
    echo "   📋 آخر 5 أسطر من السجلات:"
    tail -5 "/root/hyper-factory/logs/apps/backend_coach.log" | sed 's/^/      /'
else
    print_status "warning" "سجلات التطبيق غير موجودة"
fi

echo ""
echo "🎯 ========== تقرير النتائج =========="

# عد النتائج
success_count=$(grep -c "✅" <<< "$(cat /dev/stdin)")
warning_count=$(grep -c "⚠️" <<< "$(cat /dev/stdin)")
error_count=$(grep -c "❌" <<< "$(cat /dev/stdin)")

echo "📈 إحصائيات الفحص:"
echo "   ✅ النجاحات: $success_count"
echo "   ⚠️  التحذيرات: $warning_count"
echo "   ❌ الأخطاء: $error_count"

if [ $error_count -eq 0 ]; then
    print_status "success" "🎉 النظام يعمل بشكل ممتاز!"
elif [ $error_count -le 3 ]; then
    print_status "warning" "⚠️  النظام يعمل مع بعض المشاكل البسيطة"
else
    print_status "error" "🚨 النظام يحتاج إصلاحات عاجلة!"
fi

echo ""
echo "💡 ========== التوصيات =========="

if [ $error_count -gt 0 ]; then
    echo "   🔧 اقتراحات الإصلاح:"
    
    if ! pgrep -f "uvicorn.*9090" > /dev/null; then
        echo "      - تشغيل خدمة backend_coach: ./scripts/core/ffactory.sh start backend_coach"
    fi
    
    if [ ! -f "/root/hyper-factory/apps/backend_coach/main.py" ]; then
        echo "      - إعادة إنشاء ملف main.py"
    fi
    
    if ! python3 -c "import fastapi" &> /dev/null; then
        echo "      - تثبيت FastAPI: pip install fastapi uvicorn"
    fi
else
    echo "   🎊 كل شيء يعمل بشكل مثالي!"
    echo "   🌐 يمكنك الوصول للتطبيق على: http://localhost:9090"
    echo "   📚 الوثائق المتاحة على: http://localhost:9090/docs"
fi

echo ""
echo "==================================================="
echo "           انتهى الفحص - Hyper Factory"
echo "==================================================="
