#!/bin/bash

echo "⚡ فحص سريع - Hyper Factory"
echo "=========================="

# فحص الخدمات
echo "🔍 فحص الخدمات:"
if curl -s http://localhost:9090/api/health > /dev/null; then
    echo "✅ backend_coach شغال"
    curl -s http://localhost:9090/api/health | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(f'   🕒 {data.get(\"timestamp\", \"\")}')
"
else
    echo "❌ backend_coach متوقف"
fi

# فحص المكونات الأساسية
echo ""
echo "🔧 فحص المكونات:"
cd /root/hyper-factory
python3 -c "
import sys
sys.path.insert(0, '.')

components = []
try:
    from scripts.ai.skills_manager import SkillsManager
    components.append('✅ Skills Manager')
except: components.append('❌ Skills Manager')

try:
    from scripts.ai.llm.llm_orchestrator import LLMOrchestrator  
    components.append('✅ LLM Orchestrator')
except: components.append('❌ LLM Orchestrator')

try:
    from apps.backend_coach.main import app
    components.append('✅ FastAPI App')
except: components.append('❌ FastAPI App')

for comp in components:
    print(f'   {comp}')
"

# فحص البيانات
echo ""
echo "💾 فحص البيانات:"
if [ -f "ai/datasets/user_skills/test_user_001.json" ]; then
    echo "✅ بيانات المستخدم موجودة"
else
    echo "❌ بيانات المستخدم مفقودة"
fi

# فحص السجلات
echo ""
echo "📝 آخر السجلات:"
if [ -f "logs/apps/backend_coach.log" ]; then
    tail -3 "logs/apps/backend_coach.log" | sed 's/^/   /'
else
    echo "   ⚠️ لا توجد سجلات"
fi

echo ""
echo "🎯 الحالة النهائية:"
if curl -s http://localhost:9090/api/skills/state?user_id=test_user_001 > /dev/null; then
    echo "✅ النظام يعمل بشكل كامل 🎉"
else
    echo "⚠️  النظام يحتاج إصلاحات"
fi
