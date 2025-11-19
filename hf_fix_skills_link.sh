#!/bin/bash
echo "🔧 إصلاح ربط المهارات بالعمال المتقدمين 🎯"
echo "========================================"

# تحديث agents_levels.json بالعمال المتقدمين
python3 - << 'PYTHON'
import json
import yaml
import os

# تحميل المهارات
with open('config/skills_tracks_backend_complete.yaml', 'r') as f:
    skills_data = yaml.safe_load(f)

# إضافة العمال المتقدمين مع مهاراتهم
advanced_agents = [
    {
        "agent": "debug_expert",
        "family": "debugging",
        "display_name": "خبير التصحيح",
        "level": "advanced",
        "experience": 85,
        "skills": ["python_errors_handling", "debug_skills", "python_basics", "python_control_flow"],
        "current_track": "backend_junior_complete",
        "current_phase": "بايثون المتقدمة للمشاريع"
    },
    {
        "agent": "system_architect", 
        "family": "architecture",
        "display_name": "مهندس النظام",
        "level": "advanced", 
        "experience": 80,
        "skills": ["rest_api_concepts", "backend_framework_intro", "python_oop_basics", "web_http_fundamentals"],
        "current_track": "backend_junior_complete",
        "current_phase": "أساسيات الـ Backend Web"
    },
    {
        "agent": "technical_coach",
        "family": "training", 
        "display_name": "مدرب تقني",
        "level": "intermediate",
        "experience": 70,
        "skills": ["python_syntax_basics", "python_control_flow", "python_functions_basics", "python_collections_basics"],
        "current_track": "backend_junior_complete", 
        "current_phase": "أساسيات بايثون"
    },
    {
        "agent": "knowledge_spider",
        "family": "knowledge",
        "display_name": "جامع المعرفة", 
        "level": "intermediate",
        "experience": 65,
        "skills": ["computer_basics", "terminal_basics", "git_basics", "python_modules_packages"],
        "current_track": "backend_junior_complete",
        "current_phase": "أساسيات العمل كمبرمج"
    }
]

# حفظ العمال المتقدمين
with open('ai/memory/people/agents_levels_advanced.json', 'w') as f:
    json.dump(advanced_agents, f, indent=2, ensure_ascii=False)

print("✅ تم إنشاء العمال المتقدمين بالمهارات!")
print("📊 العمال والمهارات:")
for agent in advanced_agents:
    print(f"   - {agent['agent']}: {len(agent.get('skills', []))} مهارة")
PYTHON

echo "🎯 تم إصلاح نظام المهارات!"
