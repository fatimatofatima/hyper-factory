#!/usr/bin/env bash
set -euo pipefail

cd /root/hyper-factory

echo "== [1] BACKUP existing backend_coach =="
TS="$(date +%Y%m%d_%H%M%S)"
mkdir -p _backup_backend
[ -f apps/backend_coach/main.py ] && cp apps/backend_coach/main.py "_backup_backend/main.py.$TS"
[ -f scripts/ai/skills_manager.py ] && cp scripts/ai/skills_manager.py "_backup_backend/skills_manager.py.$TS"

echo "== [2] Ensure folders exist =="
mkdir -p scripts/ai
mkdir -p ai/datasets/user_skills
mkdir -p apps/backend_coach

echo "== [3] Write clean scripts/ai/skills_manager.py =="
cat << 'PYEOF' > scripts/ai/skills_manager.py
#!/usr/bin/env python3
import os
import json
from typing import Dict, Any


class SkillsManager:
    def __init__(self) -> None:
        # مكان تخزين حالة مهارات المستخدمين
        self.data_path = os.path.join("ai", "datasets", "user_skills")
        os.makedirs(self.data_path, exist_ok=True)

    def _file_path(self, user_id: str) -> str:
        return os.path.join(self.data_path, f"{user_id}.json")

    def get_skills_state(self, user_id: str) -> Dict[str, Any]:
        """
        إرجاع حالة المهارات لمستخدم معيّن.
        لو مفيش ملف للمستخدم → يرجّع حالة افتراضية.
        """
        path = self._file_path(user_id)
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        return {"user_id": user_id, "skills": {}, "level": "beginner"}

    def _calculate_level(self, skills: Dict[str, int]) -> str:
        """
        تحويل متوسط السكور إلى مستوى عام.
        """
        if not skills:
            return "beginner"
        values = [int(v) for v in skills.values()]
        avg = sum(values) / len(values)
        if avg < 40:
            return "beginner"
        elif avg < 75:
            return "intermediate"
        return "advanced"

    def update_skill(self, user_id: str, skill_id: str, new_score: int) -> Dict[str, Any]:
        """
        تحديث سكِل معيّن للمستخدم وحفظ الحالة على الديسك.
        """
        state = self.get_skills_state(user_id)

        if "skills" not in state or not isinstance(state["skills"], dict):
            state["skills"] = {}

        state["skills"][skill_id] = int(new_score)
        state["level"] = self._calculate_level(state["skills"])

        path = self._file_path(user_id)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(state, f, ensure_ascii=False, indent=2)

        return state
PYEOF

echo "== [4] Write clean apps/backend_coach/main.py =="
cat << 'PYEOF' > apps/backend_coach/main.py
#!/usr/bin/env python3
import os
import sys
from datetime import datetime
from typing import Any, Dict

from fastapi import FastAPI, Query, Body
from fastapi.middleware.cors import CORSMiddleware

# ضبط المسارات
APP_DIR = os.path.dirname(__file__)
ROOT_DIR = os.path.abspath(os.path.join(APP_DIR, "..", ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

from scripts.ai.llm.llm_orchestrator import LLMOrchestrator
from scripts.ai.skills_manager import SkillsManager

app = FastAPI(title="Hyper Factory - Backend Coach")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# تهيئة الأوركستريتور ومدير المهارات
_orch = LLMOrchestrator()
skills_manager = SkillsManager()


@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy ✅",
        "service": "backend_coach",
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/api/skills/state")
async def get_skills_state(user_id: str = Query(...)):
    """
    قراءة حالة مهارات مستخدم.
    """
    return skills_manager.get_skills_state(user_id)


@app.post("/api/skills/update")
async def update_skill(
    user_id: str = Query(...),
    skill_id: str = Query(...),
    new_score: int = Query(...),
):
    """
    تحديث سكِل معيّن لمستخدم.
    """
    return skills_manager.update_skill(user_id, skill_id, new_score)


@app.get("/api/orchestrator/analyze")
async def analyze_message(
    user_id: str = Query(...),
    message: str = Query(...),
):
    """
    إرجاع تحليل الرسالة (نوع الوكيل + معلومات إضافية).
    """
    return _orch.analyze_message(user_id, message)


@app.post("/api/orchestrator/smart_answer")
async def smart_answer(
    user_id: str = Query(...),
    data: Dict[str, Any] = Body(...),
):
    """
    توليد إجابة ذكية بناءً على الرسالة + الـ RAG + قواعد الـ Orchestrator.
    """
    message = data.get("message", "")
    return _orch.generate_smart_response(user_id, message)
PYEOF

echo "== [5] Done writing clean backend_coach =="
echo "الآن أعد تشغيل الخدمة يدويًا."
