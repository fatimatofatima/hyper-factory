#!/bin/bash

# لا نستخدم set -e حتى لا يتوقف الفحص عند أول خطأ
set -u

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

# عدادات
SUCCESS_COUNT=0
WARNING_COUNT=0
ERROR_COUNT=0

# تقرير JSON مبسّط
REPORT_DIR="/root/hyper-factory/reports"
mkdir -p "$REPORT_DIR"
REPORT_JSON="$REPORT_DIR/health_check_report.json"

# دالة للطباعة الملونة
print_status() {
    local level="$1"; shift
    local msg="$*"
    case "$level" in
        success) echo -e "${GREEN}✅ $msg${NC}"; ((SUCCESS_COUNT++));;
        warning) echo -e "${YELLOW}⚠️  $msg${NC}"; ((WARNING_COUNT++));;
        error)   echo -e "${RED}❌ $msg${NC}"; ((ERROR_COUNT++));;
        info)    echo -e "${BLUE}ℹ️  $msg${NC}";;
        *)       echo "$msg";;
    esac
}

# دوال مساعدة
check_file() {
    local path="$1"
    if [ -f "$path" ]; then
        print_status success "الملف موجود: $path"
        return 0
    else
        print_status error "الملف مفقود: $path"
        return 1
    fi
}

check_dir() {
    local path="$1"
    if [ -d "$path" ]; then
        print_status success "المجلد موجود: $path"
        return 0
    else
        print_status error "المجلد مفقود: $path"
        return 1
    fi
}

is_port_listening() {
    local port="$1"
    # نستخدم ss إن وجد، وإلا نfallback لـ netstat
    if command -v ss >/dev/null 2>&1; then
        ss -ltn | awk '{print $4}' | grep -qE "(:|^)$port$|:$port$"
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tulpn 2>/dev/null | grep -q ":$port "
    else
        # بدون أدوات الشبكة، نحاول اتصال TCP
        timeout 1 bash -c "</dev/tcp/localhost/$port" 2>/dev/null
    fi
}

check_service() {
    local service_name="$1"
    local port="$2"
    echo ""
    print_status info "فحص خدمة: $service_name"

    if is_port_listening "$port"; then
        print_status success "المنفذ $port يستمع لاتصالات"
    else
        print_status warning "المنفذ $port لا يستمع، سنحاول فحص الصحة مباشرة"
    fi

    # فحص الصحة
    local health_url="http://localhost:$port/api/health"
    local status_code
    status_code="$(curl -s -o /dev/null -w "%{http_code}" "$health_url" || echo 000)"
    if [ "$status_code" = "200" ]; then
        print_status success "Health يعمل (HTTP 200)"
        local health_response
        health_response="$(curl -s "$health_url" | tr -d '\n')"
        echo "   📊 حالة الخدمة: $health_response"
    else
        print_status error "Health غير متاح (HTTP $status_code) → $health_url"
    fi
}

check_endpoint() {
    local endpoint="$1"
    local expected_code="${2:-200}"
    local url="http://localhost:9090$endpoint"
    local code
    code="$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo 000)"
    if [ "$code" = "$expected_code" ]; then
        print_status success "Endpoint OK: $endpoint (HTTP $code)"
        if [ "$code" = "200" ]; then
            local content
            content="$(curl -s "$url" | head -c 120 | tr -d '\n')"
            echo "   📦 محتوى: ${content}..."
        fi
    else
        # لو الخدمة شغالة لكن الإندبوينت لسه غير متوفر نعدّه تحذير بدل خطأ
        if [ "$code" = "404" ]; then
            print_status warning "Endpoint غير موجود بعد: $endpoint (HTTP 404)"
        else
            print_status error "Endpoint فشل: $endpoint (توقع $expected_code، حصل $code)"
        fi
    fi
}

# تنظيف الشاشة
clear

echo "📁 ========== فحص هيكل الملفات =========="
check_dir "/root/hyper-factory"
check_dir "/root/hyper-factory/apps"
check_dir "/root/hyper-factory/apps/backend_coach"
check_dir "/root/hyper-factory/scripts"
check_dir "/root/hyper-factory/scripts/ai"
check_dir "/root/hyper-factory/scripts/ai/llm"
check_dir "/root/hyper-factory/config"                 # تصحيح: config تحت الجذر
check_dir "/root/hyper-factory/ai"
check_dir "/root/hyper-factory/ai/datasets"
check_dir "/root/hyper-factory/ai/datasets/user_skills"
check_dir "/root/hyper-factory/logs"
check_dir "/root/hyper-factory/logs/apps" || mkdir -p "/root/hyper-factory/logs/apps"

echo ""
echo "📄 ========== فحص الملفات الأساسية =========="
check_file "/root/hyper-factory/apps/backend_coach/main.py"
check_file "/root/hyper-factory/scripts/ai/skills_manager.py"
check_file "/root/hyper-factory/scripts/ai/llm/llm_orchestrator.py"
check_file "/root/hyper-factory/config/orchestrator.yaml"   # تصحيح المسار
check_file "/root/hyper-factory/scripts/core/ffactory.sh"

echo ""
echo "💾 ========== فحص ملفات البيانات =========="
USR_JSON="/root/hyper-factory/ai/datasets/user_skills/test_user_001.json"
if [ ! -f "$USR_JSON" ]; then
    print_status warning "إنشاء ملف بيانات تجريبي للمستخدم test_user_001..."
    mkdir -p /root/hyper-factory/ai/datasets/user_skills
    cat << 'JSONEOF' > "$USR_JSON"
{
  "user_id": "test_user_001",
  "skills": {
    "python_syntax_basics": 75,
    "python_control_flow": 60,
    "python_functions_basics": 45
  },
  "level": "intermediate",
  "track_id": "backend_junior"
}
JSONEOF
    print_status success "تم إنشاء ملف بيانات تجريبي: $USR_JSON"
else
    print_status success "بيانات المستخدم موجودة: $USR_JSON"
fi

echo ""
echo "🔧 ========== فحص التبعيات والبيئة =========="
if command -v python3 &> /dev/null; then
    print_status success "بايثون 3 مثبت"
    python3 -V | awk '{print "   🐍 " $0}'
    python3 -c "import fastapi" &>/dev/null && print_status success "FastAPI مثبت" || print_status error "FastAPI غير مثبت"
    python3 -c "import uvicorn" &>/dev/null && print_status success "uvicorn مثبت" || print_status error "uvicorn غير مثبت"
else
    print_status error "بايثون 3 غير مثبت"
fi

echo ""
echo "🚀 ========== فحص الخدمات والشبكة =========="
print_status info "فحص المنفذ 9090:"
if is_port_listening "9090"; then
    print_status success "المنفذ 9090 يستمع"
else
    print_status warning "المنفذ 9090 لا يستمع"
fi

check_service "backend_coach" "9090"

echo ""
echo "🌐 ========== فحص نقاط API =========="
# نقاط متوقعة قد تكون موجودة الآن
check_endpoint "/" 200
check_endpoint "/api/health" 200
# نقاط قد تكون غير جاهزة بعد → نعامل 404 كتحذير
check_endpoint "/api/skills/state?user_id=test_user_001" 200
check_endpoint "/api/orchestrator/analyze?user_id=test_user_001&message=test" 200

echo ""
print_status info "فحص تحديث المهارات (إن وُجد endpoint):"
update_response="$(curl -s -X POST "http://localhost:9090/api/skills/update?user_id=test_user_001&skill_id=python_syntax_basics&new_score=85" || true)"
if echo "$update_response" | grep -q "python_syntax_basics"; then
    print_status success "تحديث المهارات يعمل"
    echo "   📊 النتيجة: $update_response"
else
    print_status warning "تحديث المهارات غير متاح أو فشل"
    echo "   ℹ️  الرد: ${update_response:-<no response>}"
fi

echo ""
echo "🔍 ========== فحص المكونات الداخلية =========="
cd /root/hyper-factory || true

print_status info "فحص Skills Manager:"
python3 - <<'PY' || true
import sys
sys.path.insert(0, '/root/hyper-factory')
try:
    from scripts.ai.skills_manager import SkillsManager
    sm = SkillsManager()
    state = sm.get_user_state('health_check_user') if hasattr(sm, 'get_user_state') else {'status': 'no_method_get_user_state'}
    print('   ✅ Skills Manager يعمل بنجاح')
    print(f'   📊 نتيجة: {state}')
except Exception as e:
    print(f'   ❌ خطأ في Skills Manager: {e}')
PY

print_status info "فحص LLM Orchestrator:"
python3 - <<'PY' || true
import sys
sys.path.insert(0, '/root/hyper-factory')
try:
    from scripts.ai.llm.llm_orchestrator import LLMOrchestrator
    orch = LLMOrchestrator()
    res = None
    if hasattr(orch, 'analyze_message'):
        res = orch.analyze_message('test_user', 'عايز اتعلم بايثون')
        print(f'   🧠 نتيجة التحليل: {res}')
    else:
        print('   ⚠️  لا توجد دالة analyze_message')
    print('   ✅ LLM Orchestrator محمّل')
except Exception as e:
    print(f'   ❌ خطأ في LLM Orchestrator: {e}')
PY

echo ""
echo "📊 ========== فحص الأداء والموارد =========="
print_status info "أعلى العمليات استهلاكًا للذاكرة (python/uvicorn):"
ps aux --sort=-%mem | awk 'NR<=10 && /python|uvicorn/' || echo "   ℹ️  لا توجد عمليات بايثون/uvicorn نشطة"

echo ""
print_status info "فحص مساحة التخزين:"
du -sh /root/hyper-factory | awk '{print "   💾 حجم المشروع: " $1}'
du -sh /root/hyper-factory/ai/datasets | awk '{print "   🗃️  حجم البيانات: " $1}' 2>/dev/null || echo "   🗃️  لا توجد بيانات حالياً"

echo ""
echo "📝 ========== فحص السجلات =========="
APP_LOG="/root/hyper-factory/logs/apps/backend_coach.log"
if [ -f "$APP_LOG" ]; then
    print_status success "سجلات التطبيق موجودة: $APP_LOG"
    echo "   📋 آخر 5 أسطر:"
    tail -5 "$APP_LOG" | sed 's/^/      /'
else
    print_status warning "سجلات التطبيق غير موجودة بعد: $APP_LOG"
fi

echo ""
echo "🎯 ========== تقرير النتائج =========="
echo "📈 إحصائيات الفحص:"
echo "   ✅ النجاحات: $SUCCESS_COUNT"
echo "   ⚠️  التحذيرات: $WARNING_COUNT"
echo "   ❌ الأخطاء: $ERROR_COUNT"

STATUS="ok"
if [ $ERROR_COUNT -eq 0 ]; then
    print_status success "🎉 النظام يعمل بشكل ممتاز!"
    STATUS="ok"
elif [ $ERROR_COUNT -le 3 ]; then
    print_status warning "⚠️  النظام يعمل مع بعض المشاكل البسيطة"
    STATUS="degraded"
else
    print_status error "🚨 النظام يحتاج إصلاحات عاجلة!"
    STATUS="critical"
fi

# حفظ تقرير JSON مبسّط
cat > "$REPORT_JSON" <<JSON
{
  "status": "$STATUS",
  "success": $SUCCESS_COUNT,
  "warnings": $WARNING_COUNT,
  "errors": $ERROR_COUNT,
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%S)"
}
JSON
print_status info "تم حفظ تقرير JSON: $REPORT_JSON"

echo ""
echo "💡 ========== التوصيات =========="
if [ $ERROR_COUNT -gt 0 ]; then
    echo "   🔧 اقتراحات الإصلاح:"
    if ! is_port_listening "9090"; then
        echo "      - تشغيل خدمة backend_coach: ./scripts/core/ffactory.sh start backend_coach"
    fi
    if [ ! -f "/root/hyper-factory/apps/backend_coach/main.py" ]; then
        echo "      - إعادة إنشاء ملف main.py لتطبيق Backend Coach"
    fi
    python3 -c "import fastapi, uvicorn" &>/dev/null || echo "      - تثبيت المتطلبات: pip install fastapi uvicorn pydantic"
else
    echo "   🎊 كل شيء يعمل بشكل مثالي!"
    echo "   🌐 الوصول للتطبيق: http://localhost:9090"
    echo "   📚 الوثائق (إن متاحة): http://localhost:9090/docs"
fi

echo ""
echo "==================================================="
echo "           انتهى الفحص - Hyper Factory"
echo "==================================================="
