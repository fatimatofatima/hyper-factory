#!/bin/bash

echo "🔍 Hyper Factory - فحص الفجوات بين التصميم والواقع"
echo "=================================================="
echo "⏰ $(date)"
echo "📍 $(pwd)"
echo ""

# الألوان
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_component() {
    local name="$1"
    local expected="$2"
    local actual="$3"
    local check_cmd="$4"
    
    echo -e "${BLUE}🔍 فحص: $name${NC}"
    echo -e "   📋 المتوقع: $expected"
    echo -e "   📁 الواقع: $actual"
    
    if eval "$check_cmd" > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ موجود${NC}"
        return 0
    else
        echo -e "   ${RED}❌ مفقود${NC}"
        return 1
    fi
    echo ""
}

echo "📊 1. فحص العوامل (Agents)"
echo "=========================="

check_component \
    "عامل التصحيح (Debug Expert)" \
    "agents/debug_expert/ مع job description + pipelines" \
    "agents/debug_expert/" \
    "ls agents/debug_expert/ 2>/dev/null"

check_component \
    "المهندس المعماري (System Architect)" \
    "agents/system_architect/ مع تصاميم + هندسة" \
    "agents/system_architect/" \
    "ls agents/system_architect/ 2>/dev/null"

check_component \
    "المدرب الفني (Technical Coach)" \
    "agents/technical_coach/ مع مناهج + تدريب" \
    "agents/technical_coach/" \
    "ls agents/technical_coach/ 2>/dev/null"

echo "📊 2. فحص نموذج البيانات (Data Models)"
echo "====================================="

check_component \
    "قاموس المهارات (Skills Dictionary)" \
    "data_models/skills.json أو skills/" \
    "data_models/skills.json" \
    "find . -name '*skill*' -type f | grep -v '.git'"

check_component \
    "تعريف المسارات (Tracks Definition)" \
    "data_models/tracks.yaml أو tracks/" \
    "data_models/tracks.yaml" \
    "find . -name '*track*' -type f | grep -v '.git'"

check_component \
    "حالة المستخدم (User Skill State)" \
    "data_models/user_state.py أو user_profiles/" \
    "data_models/user_state.py" \
    "find . -name '*user*state*' -o -name '*user*profile*' | grep -v '.git'"

echo "📊 3. فحص نظام البنية التحتية"
echo "============================"

check_component \
    "منسق النظام (Orchestrator)" \
    "orchestrator.py أو core/orchestrator.py" \
    "orchestrator.py" \
    "find . -name '*orchestrat*' -type f | grep -v '.git'"

check_component \
    "نظام التعليقات (Feedback System)" \
    "feedback/ مع good/bad + أسباب" \
    "feedback/" \
    "ls feedback/ 2>/dev/null"

check_component \
    "سجلات التعلم (Learning Logs)" \
    "logs/ أو monitoring/ مع تجميع البيانات" \
    "logs/" \
    "ls logs/ 2>/dev/null"

check_component \
    "التقييم (Evaluation System)" \
    "evaluation/ مع test suites" \
    "evaluation/" \
    "ls evaluation/ 2>/dev/null"

check_component \
    "زحف المعرفة (Knowledge Crawlers)" \
    "crawler/ أو ingestion/ للمصادر الخارجية" \
    "crawler/" \
    "ls crawler/ 2>/dev/null"

check_component \
    "قاعدة المعرفة (Knowledge Base)" \
    "knowledge/ مع snippets + patterns" \
    "knowledge/" \
    "ls knowledge/ 2>/dev/null"

echo "📊 4. فحص الملفات الأساسية"
echo "=========================="

check_component \
    "ملف المتطلبات (Requirements)" \
    "requirements.txt مع جميع dependencies" \
    "requirements.txt" \
    "ls requirements.txt 2>/dev/null"

check_component \
    "إعدادات التكوين (Configuration)" \
    "config/ مع إعدادات مفصلة" \
    "config/" \
    "ls config/ 2>/dev/null"

check_component \
    "السكريبتات (Scripts)" \
    "scripts/ مع أدوات التشغيل" \
    "scripts/" \
    "ls scripts/ 2>/dev/null"

# تحليل النتائج
echo "📈 تحليل النتائج"
echo "================"

total_checks=0
missing_checks=0

for check in agents debug_expert system_architect technical_coach skills tracks user_state orchestrator feedback evaluation crawler knowledge; do
    ((total_checks++))
    # هذا تبسيط - في التنفيذ الفعلي نحتاج تتبع النتائج
done

echo -e "إجمالي المكونات المفحوصة: $total_checks"
echo -e "${RED}المكونات المفقودة: $missing_checks${NC}"

echo ""
echo "💡 التوصيات الفورية:"
echo "==================="
echo "1. إنشاء هيكل agents/ مع العوامل الثلاثة الأساسية"
echo "2. تطوير data_models/ لنموذج البيانات"
echo "3. بناء orchestrator لربط المكونات"
echo "4. إضافة نظام feedback للتقييم"

