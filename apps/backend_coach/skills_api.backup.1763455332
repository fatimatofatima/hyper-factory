#!/usr/bin/env python3
"""
skills_api.py
Router موحّد:
- /api/skills/state
- /api/skills/update
- /api/orchestrator/analyze
- /api/orchestrator/smart_answer
"""

import os
import sys
from datetime import datetime
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel

# إعداد المسارات
APP_DIR = os.path.dirname(__file__)
ROOT_DIR = os.path.abspath(os.path.join(APP_DIR, "..", ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

from scripts.ai.llm.llm_orchestrator import LLMOrchestrator
from scripts.ai.skills_manager import SkillsManager
from scripts.ai.factory_metrics import log_metric

router = APIRouter(tags=["factory"])

# instances
orchestrator = LLMOrchestrator()
skills_manager = SkillsManager()

# خريطة: agent -> skills
AGENT_SKILL_MAP = {
    "debug_expert": ["python_errors_handling"],
    "technical_coach": ["python_control_flow", "python_functions_basics"],
    "system_architect": ["backend_framework_intro", "db_modeling_basic"],
    "knowledge_spider": ["web_http_fundamentals", "rest_api_concepts"],
}

# ===== نماذج الطلبات =====

class SmartAnswerRequest(BaseModel):
    message: str
    user_id: str = "anonymous"

# ===== Skills Endpoints =====

@router.get("/skills/state")
async def get_skills_state(
    user_id: str = Query("anonymous", description="معرّف المستخدم"),
):
    """
    حالة مهارات مستخدم واحد.
    """
    try:
        profile = skills_manager.get_user_skills(user_id)
        weak = skills_manager.get_weak_skills(user_id)
        return {
            "success": True,
            "user_id": user_id,
            "profile": {
                "track": profile["track_id"],
                "current_phase": profile["current_phase"],
                "overall_progress": profile["overall_progress"],
                "sessions_count": profile["sessions_count"],
                "weak_skills_count": len(weak),
            },
            "weak_skills": weak[:3],
            "timestamp": datetime.utcnow().isoformat(),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"skills_state error: {e}")


@router.post("/skills/update")
async def update_skill_score(
    user_id: str = Query(..., description="معرّف المستخدم"),
    skill_id: str = Query(..., description="معرّف المهارة"),
    new_score: int = Query(..., ge=0, le=100, description="درجة المهارة (0-100)"),
):
    """
    تعديل درجة مهارة واحدة لمستخدم.
    """
    try:
        profile = skills_manager.update_skill_score(user_id, skill_id, new_score)
        return {
            "success": True,
            "user_id": user_id,
            "skill_id": skill_id,
            "new_score": new_score,
            "overall_progress": profile["overall_progress"],
            "current_phase": profile["current_phase"],
            "timestamp": datetime.utcnow().isoformat(),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"skills_update error: {e}")

# ===== Orchestrator Endpoints =====

@router.get("/orchestrator/analyze")
async def orchestrator_analyze(
    message: str = Query(..., description="رسالة المستخدم"),
    user_id: str = Query("anonymous", description="معرّف المستخدم"),
):
    """
    تحليل الرسالة وتحديد الـ agent الأنسب.
    """
    try:
        result = orchestrator.analyze_message(message, user_id)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"analyze error: {e}")


@router.post("/orchestrator/smart_answer")
async def orchestrator_smart_answer(payload: SmartAnswerRequest):
    """
    إجابة ذكية + تحديث مهارات + تسجيل metrics (بسيط).
    Body JSON:
    {
      "message": "...",
      "user_id": "..."
    }
    """
    user_id = payload.user_id or "anonymous"
    message = payload.message

    try:
        analysis = orchestrator.analyze_message(message, user_id)
        target_agent = analysis.get("target_agent", "debug_expert")

        # تسجيل metric بسيط
        try:
            log_metric(
                agent=target_agent,
                event_type="route_decision",
                user_id=user_id,
                meta={"confidence": analysis.get("confidence", 0.0)},
            )
        except Exception as m_err:
            print(f"[METRICS] log_metric error: {m_err}")

        # تحديث مهارات أوتوماتيك حسب الـ agent
        skill_updates = []
        if target_agent in AGENT_SKILL_MAP:
            for sk in AGENT_SKILL_MAP[target_agent]:
                prof = skills_manager.get_user_skills(user_id)
                current = prof["skills"].get(sk, {}).get("score", 0)
                new_score = min(current + 10, 100)
                prof = skills_manager.update_skill_score(user_id, sk, new_score)
                skill_updates.append(
                    {"skill_id": sk, "old_score": current, "new_score": new_score}
                )

        overall = 0
        prof = skills_manager.get_user_skills(user_id)
        overall = prof.get("overall_progress", 0)

        return {
            "success": True,
            "user_id": user_id,
            "message": message,
            "analysis": analysis,
            "result_mode": "agent_only",
            "skill_updates": skill_updates,
            "overall_progress": overall,
            "timestamp": datetime.utcnow().isoformat(),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"smart_answer error: {e}")
