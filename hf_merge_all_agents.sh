#!/bin/bash
echo "🔄 دمج جميع العمال في نظام واحد 🎪"
echo "================================"

python3 - << 'PYTHON'
import json

# تحميل العمال الأساسيين
with open('ai/memory/people/agents_levels.json', 'r') as f:
    basic_agents = json.load(f)

# تحميل العمال المتقدمين  
with open('ai/memory/people/agents_levels_advanced.json', 'r') as f:
    advanced_agents = json.load(f)

# دمج جميع العمال
all_agents = basic_agents + advanced_agents

# حفظ النتيجة
with open('ai/memory/people/all_agents_complete.json', 'w') as f:
    json.dump(all_agents, f, indent=2, ensure_ascii=False)

print(f"✅ تم دمج {len(all_agents)} عامل في نظام واحد!")
print("📊 أنواع العمال:")
print(f"   - عمال أساسيين: {len(basic_agents)}")
print(f"   - عمال متقدمين: {len(advanced_agents)}")
print(f"   - الإجمالي: {len(all_agents)}")
PYTHON

echo "🎉 اكتمل نظام العمال الكامل!"
