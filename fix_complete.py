#!/usr/bin/env python3
import os
import shutil

def fix_skills_manager():
    """إصلاح ملف skills_manager"""
    content = '''#!/usr/bin/env python3
import os
import json
from typing import Dict, Any

class SkillsManager:
    def __init__(self):
        self.data_path = "ai/datasets/user_skills"
        os.makedirs(self.data_path, exist_ok=True)
    
    def get_skills_state(self, user_id: str) -> Dict[str, Any]:
        file_path = f"{self.data_path}/{user_id}.json"
        if os.path.exists(file_path):
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        
        return {
            "user_id": user_id,
            "skills": {
                "python_syntax_basics": 0,
                "python_control_flow": 0,
                "python_functions_basics": 0
            },
            "level": "beginner"
        }
    
    def update_skill(self, user_id: str, skill_id: str, new_score: int) -> Dict[str, Any]:
        state = self.get_skills_state(user_id)
        state["skills"][skill_id] = new_score
        state["level"] = self._calculate_level(state["skills"])
        
        file_path = f"{self.data_path}/{user_id}.json"
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(state, f, ensure_ascii=False, indent=2)
        
        return state
    
    def _calculate_level(self, skills: Dict[str, int]) -> str:
        if not skills:
            return "beginner"
        
        avg_score = sum(skills.values()) / len(skills)
        if avg_score < 40:
            return "beginner"
        elif avg_score < 70:
            return "intermediate"
        else:
            return "advanced"
'''
    with open('/root/hyper-factory/scripts/ai/skills_manager.py', 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ تم إصلاح skills_manager.py")

def fix_main_py():
    """إصلاح ملف main.py"""
    content = '''#!/usr/bin/env python3
import os
import sys
from datetime import datetime
from typing import Any, Dict, Optional

from fastapi import FastAPI, Query, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware

# إعداد المسارات
APP_DIR = os.path.dirname(__file__)
ROOT_DIR = os.path.abspath(os.path.join(APP_DIR, "..", ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

print(f"🚀 تحميل Hyper Factory Backend Coach من: {APP_DIR}")

# تهيئة التطبيق
app = FastAPI(
    title="Hyper Factory - Backend Coach",
    description="نظام التعلم الذكي المدعوم بالذكاء الاصطناعي",
    version="2.0.0"
)

# إعداد CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# استيراد المكونات
try:
    from scripts.ai.llm.llm_orchestrator import LLMOrchestrator
    from scripts.ai.skills_manager import SkillsManager
    
    _orch = LLMOrchestrator()
    skills_manager = SkillsManager()
    
    print("✅ LLMOrchestrator جاهز للعمل")
    print("✅ SkillsManager جاهز للعمل")
except Exception as e:
    print(f"❌ خطأ في تحميل المكونات: {e}")
    _orch = None
    skills_manager = None

@app.get("/")
async def root():
    return {
        "message": "🏭 مصنع العمّال الأذكياء - Backend Coach API",
        "version": "2.0.0",
        "status": "يعمل 🚀",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy ✅",
        "service": "backend_coach",
        "timestamp": datetime.utcnow().isoformat(),
    }

@app.get("/api/skills/state")
async def get_skills_state(user_id: str = Query(...)):
    if not skills_manager:
        raise HTTPException(status_code=500, detail="SkillsManager غير متوفر")
    return skills_manager.get_skills_state(user_id)

@app.post("/api/skills/update")
async def update_skill(
    user_id: str = Query(...),
    skill_id: str = Query(...),
    new_score: int = Query(...)
):
    if not skills_manager:
        raise HTTPException(status_code=500, detail="SkillsManager غير متوفر")
    return skills_manager.update_skill(user_id, skill_id, new_score)

@app.get("/api/orchestrator/analyze")
async def analyze_message(
    user_id: str = Query(...),
    message: str = Query(...)
):
    if not _orch:
        raise HTTPException(status_code=500, detail="LLMOrchestrator غير متوفر")
    return _orch.analyze_message(user_id, message)

@app.post("/api/orchestrator/smart_answer")
async def smart_answer(
    user_id: str = Query(...),
    data: Dict[str, Any] = Body(...)
):
    if not _orch:
        raise HTTPException(status_code=500, detail="LLMOrchestrator غير متوفر")
    message = data.get("message", "")
    return _orch.generate_smart_response(user_id, message)

print("🎉 تم تهيئة جميع المكونات بنجاح")
print("🎯 جميع مسارات الـAPI مسجلة وجاهزة!")
'''
    with open('/root/hyper-factory/apps/backend_coach/main.py', 'w', encoding='utf-8') as f:
        f.write(content)
    print("✅ تم إصلاح main.py")

if __name__ == "__main__":
    fix_skills_manager()
    fix_main_py()
    print("🎊 تم الإصلاح الشامل بنجاح!")
