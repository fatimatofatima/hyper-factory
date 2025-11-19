#!/usr/bin/env python3
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

# تهيئة المكونات
skills_manager = None
_orch = None

try:
    from scripts.ai.skills_manager import SkillsManager
    skills_manager = SkillsManager()
    print("✅ SkillsManager جاهز للعمل")
except Exception as e:
    print(f"❌ خطأ في تحميل SkillsManager: {e}")

try:
    from scripts.ai.llm.llm_orchestrator import LLMOrchestrator
    _orch = LLMOrchestrator()
    print("✅ LLMOrchestrator جاهز للعمل")
except Exception as e:
    print(f"❌ خطأ في تحميل LLMOrchestrator: {e}")

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
    try:
        result = skills_manager.get_skills_state(user_id)
        print(f"📊 جلب حالة المهارات للمستخدم: {user_id}")
        return result
    except Exception as e:
        print(f"❌ خطأ في جلب حالة المهارات: {e}")
        raise HTTPException(status_code=500, detail=f"خطأ في جلب حالة المهارات: {e}")

@app.post("/api/skills/update")
async def update_skill(
    user_id: str = Query(...),
    skill_id: str = Query(...),
    new_score: int = Query(...)
):
    if not skills_manager:
        raise HTTPException(status_code=500, detail="SkillsManager غير متوفر")
    try:
        result = skills_manager.update_skill(user_id, skill_id, new_score)
        print(f"🔄 تحديث المهارة: {skill_id} للمستخدم: {user_id} إلى: {new_score}")
        return result
    except Exception as e:
        print(f"❌ خطأ في تحديث المهارة: {e}")
        raise HTTPException(status_code=500, detail=f"خطأ في تحديث المهارة: {e}")

@app.get("/api/orchestrator/analyze")
async def analyze_message(
    user_id: str = Query(...),
    message: str = Query(...)
):
    if not _orch:
        raise HTTPException(status_code=500, detail="LLMOrchestrator غير متوفر")
    try:
        result = _orch.analyze_message(user_id, message)
        print(f"🎯 تحليل الرسالة للمستخدم: {user_id} - الرسالة: {message}")
        return result
    except Exception as e:
        print(f"❌ خطأ في تحليل الرسالة: {e}")
        raise HTTPException(status_code=500, detail=f"خطأ في تحليل الرسالة: {e}")

@app.post("/api/orchestrator/smart_answer")
async def smart_answer(
    user_id: str = Query(...),
    data: Dict[str, Any] = Body(...)
):
    if not _orch:
        raise HTTPException(status_code=500, detail="LLMOrchestrator غير متوفر")
    try:
        message = data.get("message", "")
        result = _orch.generate_smart_response(user_id, message)
        print(f"🤖 إجابة ذكية للمستخدم: {user_id} - الرسالة: {message}")
        return result
    except Exception as e:
        print(f"❌ خطأ في توليد الإجابة: {e}")
        raise HTTPException(status_code=500, detail=f"خطأ في توليد الإجابة: {e}")

print("🎉 تم تهيئة جميع المكونات بنجاح")
print("🎯 جميع مسارات الـAPI مسجلة وجاهزة!")

if __name__ == "__main__":
    import uvicorn
    print("🚀 تشغيل خادم FastAPI على port 9090...")
    uvicorn.run(app, host="0.0.0.0", port=9090, log_level="info")
