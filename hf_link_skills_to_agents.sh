#!/bin/bash
echo "🔗 ربط المهارات بالعمال 🎯"
echo "========================"

# تحديث agents_levels.json بالمهارات
python3 - << 'PYTHON'
import json
import yaml
import os

# تحميل المهارات
with open('config/skills_tracks_backend_complete.yaml', 'r') as f:
    skills_data = yaml.safe_load(f)

# تحميل العمال الحاليين
with open('ai/memory/people/agents_levels.json', 'r') as f:
    agents = json.load(f)

# تعيين مهارات لكل عامل
skills_mapping = {
    "debug_expert": ["python_errors_handling", "debug_skills", "python_basics"],
    "system_architect": ["rest_api_concepts", "backend_framework_intro", "python_oop_basics"],
    "technical_coach": ["python_syntax_basics", "python_control_flow", "python_functions_basics"],
    "knowledge_spider": ["computer_basics", "terminal_basics", "git_basics"]
}

# تحديث العمال بالمهارات
for agent in agents:
    agent_name = agent["agent"]
    if agent_name in skills_mapping:
        agent["skills"] = skills_mapping[agent_name]
        agent["current_track"] = "backend_junior_complete"

# حفظ التحديثات
with open('ai/memory/people/agents_levels.json', 'w') as f:
    json.dump(agents, f, indent=2, ensure_ascii=False)

print("✅ تم ربط المهارات بالعمال!")
print("📊 العمال والمهارات:")
for agent in agents:
    print(f"   - {agent['agent']}: {len(agent.get('skills', []))} مهارة")
PYTHON

echo "🎯 تم تحديث نظام المهارات بالكامل!"
