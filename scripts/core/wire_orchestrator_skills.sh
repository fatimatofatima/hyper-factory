#!/bin/bash
set -e

BASE_DIR="/root/hyper-factory"
APP_DIR="$BASE_DIR/apps/backend_coach"
SKILLS_TRACKS_DIR="$BASE_DIR/ai/skills_tracks"
MAIN_PY="$APP_DIR/main.py"

echo "[1/3] إعداد ملف مسار المهارات backend_junior_skills.yaml ..."
mkdir -p "$SKILLS_TRACKS_DIR"

if [ -f "$SKILLS_TRACKS_DIR/backend_junior_skills.yaml" ]; then
  cp "$SKILLS_TRACKS_DIR/backend_junior_skills.yaml" \
     "$SKILLS_TRACKS_DIR/backend_junior_skills.yaml.bak.$(date +%s)"
fi

cat > "$SKILLS_TRACKS_DIR/backend_junior_skills.yaml" << 'YAML'
track:
  id: "backend_junior"
  name: "مسار Backend Junior"
  description: "مسار تطوير مهارات Backend من الصفر حتى التشغيل"

phases:
  - id: "phase_0"
    name: "أساسيات العمل كمبرمج"
    skills:
      - id: "computer_basics"
        name: "أساسيات الكمبيوتر والملفات"
        description: "التعامل مع الملفات، المسارات، الـ ZIP، فك/ضغط، تنصيب برامج"
        max_score: 100

      - id: "terminal_basics"
        name: "أساسيات الـ Terminal"
        description: "أوامر cd, ls, mkdir, rm, python, pip بشكل يومي"
        max_score: 100

      - id: "git_basics"
        name: "أساسيات Git"
        description: "git init / add / commit / push / clone + GitHub + branches"
        max_score: 100

  - id: "phase_1"
    name: "أساسيات بايثون"
    skills:
      - id: "python_syntax_basics"
        name: "تركيب لغة بايثون"
        description: "متغيرات، أنواع بيانات، عمليات منطقية وحسابية"
        max_score: 100

      - id: "python_control_flow"
        name: "التحكم في سير التنفيذ"
        description: "if / elif / else + for / while + فهم indentation"
        max_score: 100

      - id: "python_functions_basics"
        name: "الدوال الأساسية"
        description: "تعريف دالة، parameters, return, scope بسيط"
        max_score: 100

      - id: "python_collections_basics"
        name: "التراكيب (قوائم، قواميس، مجموعات)"
        description: "list / dict / set / tuple + العمليات الأساسية عليهم"
        max_score: 100

  - id: "phase_2"
    name: "بايثون المتقدمة للمشاريع"
    skills:
      - id: "python_oop_basics"
        name: "أساسيات الكائنات"
        description: "class / object / __init__ / attributes / methods"
        max_score: 100

      - id: "python_errors_handling"
        name: "التعامل مع الأخطاء"
        description: "try/except/finally + raise + فهم Traceback"
        max_score: 100

      - id: "python_modules_packages"
        name: "الوحدات والحزم"
        description: "import / from / إنشاء module واستخدام مكتبات خارجية"
        max_score: 100

      - id: "python_venv_pip"
        name: "بيئات العمل الافتراضية"
        description: "venv / pip / requirements.txt"
        max_score: 100

  - id: "phase_3"
    name: "أساسيات Backend Web"
    skills:
      - id: "web_http_fundamentals"
        name: "أساسيات HTTP"
        description: "request/response, methods (GET/POST/PUT/DELETE), status codes"
        max_score: 100

      - id: "rest_api_concepts"
        name: "مفاهيم REST API"
        description: "resources, endpoints, JSON, stateless"
        max_score: 100

      - id: "backend_framework_intro"
        name: "التعرف على إطار عمل Backend"
        description: "اختيار FastAPI أو Django وفهم هيكل مشروع بسيط"
        max_score: 100

      - id: "request_response_handling"
        name: "التعامل مع الطلب/الاستجابة"
        description: "تمرير JSON بسيط، إرجاع response منظم"
        max_score: 100

  - id: "phase_4"
    name: "قواعد بيانات"
    skills:
      - id: "db_relational_basics"
        name: "أساسيات قواعد البيانات العلاقية"
        description: "tables, rows, columns, primary key, foreign key"
        max_score: 100

      - id: "sql_query_basics"
        name: "أساسيات SQL"
        description: "SELECT / INSERT / UPDATE / DELETE + WHERE + ORDER BY + LIMIT"
        max_score: 100

      - id: "db_modeling_basic"
        name: "نمذجة البيانات البسيطة"
        description: "نمذجة Users, Tasks, Orders بشكل بسيط"
        max_score: 100

      - id: "orm_basics"
        name: "أساسيات ORM"
        description: "التعامل مع DB من خلال كود Python (Django ORM أو SQLAlchemy)"
        max_score: 100

  - id: "phase_5"
    name: "Backend Craft"
    skills:
      - id: "auth_basics"
        name: "أساسيات التحقق من الهوية"
        description: "حماية login/logout, tokens/session بسيطة"
        max_score: 100

      - id: "validation_and_schemas"
        name: "التحقق من البيانات"
        description: "استخدام Pydantic أو Schemas لضمان صحة الـ input"
        max_score: 100

      - id: "logging_basics"
        name: "تسجيل الأحداث"
        description: "تسجيل أخطاء وأحداث مهمة في السيرفر"
        max_score: 100

      - id: "testing_basics"
        name: "أساسيات الاختبارات"
        description: "unit tests بسيطة لـ endpoint واحد على الأقل"
        max_score: 100

  - id: "phase_6"
    name: "التشغيل (Deployment)"
    skills:
      - id: "environments_config"
        name: "بيئات التشغيل والإعدادات"
        description: "ملفات إعداد dev / staging / prod + env variables"
        max_score: 100

      - id: "basic_deployment_vps"
        name: "نشر بسيط على VPS"
        description: "تشغيل مشروع Backend على VPS (gunicorn/uvicorn + reverse proxy بسيط)"
        max_score: 100

      - id: "container_intro"
        name: "مقدمة Docker"
        description: "مفهوم container، بناء صورة بسيطة وتشغيلها"
        max_score: 100

progression_rules:
  phase_completion_threshold: 70
  skill_mastery_threshold: 80
YAML

echo "[2/3] إنشاء skills_api.py فيه Orchestrator + Skills endpoints ..."
mkdir -p "$APP_DIR"

cat > "$APP_DIR/skills_api.py" << 'PY'
#!/usr/bin/env python3
"""
skills_api.py

Router موحّد يربط:
- LLMOrchestrator (Routing + RAG-MVP)
- SkillsManager (نظام المهارات)
ويعرّض 3 endpoints تحت prefix /api:
- POST /api/orchestrator/answer
- GET  /api/skills/state
- POST /api/skills/update
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional, Dict, Any
import os
import sys

router = APIRouter()

# إعداد المسار لرؤية scripts/ai/*
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if ROOT_DIR not in sys.path:
    sys.path.append(ROOT_DIR)

from scripts.ai.llm.llm_orchestrator import LLMOrchestrator  # type: ignore
from scripts.ai.skills_manager import SkillsManager          # type: ignore

orchestrator = LLMOrchestrator()
skills_manager = SkillsManager()

# خريطة: أي Agent → مهارات يتم تحسينها مع كل Session
AGENT_SKILL_MAP = {
    "technical_coach": ["python_control_flow", "python_functions_basics"],
    "debug_expert": ["python_errors_handling"],
    "system_architect": ["backend_framework_intro", "db_modeling_basic"],
    "knowledge_spider": ["web_http_fundamentals"],
}


def _auto_update_skills(user_id: str, target_agent: Optional[str]) -> None:
    """
    تحديث أوتوماتيك لمجموعة مهارات بناء على الـ agent.

    سياسة بسيطة:
    - لو score < 40 → +15
    - لو 40 <= score < 70 → +10
    - لو score >= 70 → +5
    """
    if not target_agent:
        return

    skills_ids = AGENT_SKILL_MAP.get(target_agent, [])
    if not skills_ids:
        return

    profile = skills_manager.get_user_skills(user_id)

    for skill_id in skills_ids:
        current = profile["skills"].get(skill_id, {}).get("score", 0)
        if current < 40:
            delta = 15
        elif current < 70:
            delta = 10
        else:
            delta = 5

        new_score = min(current + delta, 100)
        skills_manager.update_skill_score(
            user_id,
            skill_id,
            new_score,
            practice_context={"source": "auto_session", "agent": target_agent},
        )


@router.post("/orchestrator/answer")
async def orchestrator_answer(payload: Dict[str, Any]):
    """
    واجهة المصنع الموحدة:
    - input: { "message": "...", "user_id": "..." }
    - output: routing + RAG contexts + metadata
    - يقوم بتحديث المهارات أوتوماتيكياً حسب الـ agent
    """
    message = (payload or {}).get("message", "")
    user_id = (payload or {}).get("user_id", "anonymous")

    if not message:
        raise HTTPException(status_code=400, detail="message مطلوب")

    orchestration = orchestrator.answer_with_rag(message, user_id=user_id)
    target_agent = orchestration.get("routing", {}).get("target_agent")

    _auto_update_skills(user_id, target_agent)

    return orchestration


@router.get("/skills/state")
async def get_skills_state(
    user_id: str = Query("anonymous", description="معرّف المستخدم"),
):
    """
    الحصول على حالة مهارات المستخدم + أهم المهارات الضعيفة
    """
    profile = skills_manager.get_user_skills(user_id)
    weak_skills = skills_manager.get_weak_skills(user_id)

    return {
        "success": True,
        "user_id": user_id,
        "profile": {
            "track": profile["track_id"],
            "current_phase": profile["current_phase"],
            "overall_progress": profile["overall_progress"],
            "sessions_count": profile["sessions_count"],
            "weak_skills_count": len(weak_skills),
        },
        "weak_skills": weak_skills[:3],
    }


@router.post("/skills/update")
async def manual_update_skill(
    user_id: str = Query(..., description="معرّف المستخدم"),
    skill_id: str = Query(..., description="معرّف المهارة (كما في YAML)"),
    new_score: int = Query(..., ge=0, le=100, description="الدرجة الجديدة (0-100)"),
):
    """
    تحديث يدوي لدرجة مهارة معينة للمستخدم
    """
    profile = skills_manager.update_skill_score(
        user_id,
        skill_id,
        new_score,
        practice_context={"source": "manual_update"},
    )

    return {
        "success": True,
        "user_id": user_id,
        "skill_id": skill_id,
        "new_score": new_score,
        "overall_progress": profile["overall_progress"],
        "current_phase": profile["current_phase"],
    }
PY

echo "[3/3] ربط skills_api.Router مع FastAPI app في main.py ..."
if [ ! -f "$MAIN_PY" ]; then
  echo "❌ لم يتم العثور على $MAIN_PY"
  exit 1
fi

# إضافة import + include_router في نهاية main.py لو مش موجودين
if ! grep -q "from .skills_api import router as skills_router" "$MAIN_PY"; then
  echo "" >> "$MAIN_PY"
  echo "# Auto-wired skills & orchestrator router" >> "$MAIN_PY"
  echo "from .skills_api import router as skills_router  # noqa: E402" >> "$MAIN_PY"
fi

if ! grep -q "include_router(skills_router" "$MAIN_PY"; then
  echo "app.include_router(skills_router, prefix=\"/api\")" >> "$MAIN_PY"
fi

echo "✅ الربط اكتمل بنجاح."
