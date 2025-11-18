#!/usr/bin/env bash
set -euo pipefail

cd /root/hyper-factory

FILE="apps/backend_coach/main.py"

if [ ! -f "$FILE" ]; then
  echo "❌ $FILE غير موجود"
  exit 1
fi

echo "📦 Backup للملف الحالي..."
cp "$FILE" "${FILE}.bak_$(date +%Y%m%d_%H%M%S)"

# لو الـ routes موجودة، لا نكررها
if grep -q "/api/skills/state" "$FILE"; then
  echo "ℹ️ يبدو أن بلوك الـ routes موجود بالفعل في $FILE – لن أضيفه مرة ثانية."
  exit 0
fi

echo "✏️ إضافة بلوك الـ routes في نهاية $FILE ..."

cat << 'PYEOF' >> "$FILE"

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
    return skills_manager.get_skills_state(user_id)

@app.post("/api/skills/update")
async def update_skill(
    user_id: str = Query(...),
    skill_id: str = Query(...),
    new_score: int = Query(...)
):
    return skills_manager.update_skill(user_id, skill_id, new_score)

@app.get("/api/orchestrator/analyze")
async def analyze_message(
    user_id: str = Query(...),
    message: str = Query(...)
):
    return _orch.analyze_message(user_id, message)

@app.post("/api/orchestrator/smart_answer")
async def smart_answer(
    user_id: str = Query(...),
    data: Dict[str, Any] = Body(...)
):
    message = data.get("message", "")
    return _orch.generate_smart_response(user_id, message)
PYEOF

echo "✅ تم حقن البلوك في $FILE"
