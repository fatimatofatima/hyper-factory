#!/bin/bash
# إضافة endpoint /api/orchestrator/analyze بشكل آمن

set -e

BASE_DIR="/root/hyper-factory"
APP_DIR="$BASE_DIR/apps/backend_coach"
MAIN_PY="$APP_DIR/main.py"

echo "== إضافة /api/orchestrator/analyze بشكل آمن =="

if [ ! -f "$MAIN_PY" ]; then
  echo "❌ main.py غير موجود في: $MAIN_PY"
  exit 1
fi

# 1) Backup
BACKUP="$MAIN_PY.bak_$(date +%Y%m%d_%H%M%S)"
cp "$MAIN_PY" "$BACKUP"
echo "📦 Backup: $BACKUP"

# 2) التأكد من وجود Query في import
if ! grep -q "from fastapi import FastAPI, HTTPException, Query" "$MAIN_PY"; then
  if grep -q "from fastapi import FastAPI, HTTPException" "$MAIN_PY"; then
    sed -i 's/from fastapi import FastAPI, HTTPException/from fastapi import FastAPI, HTTPException, Query/' "$MAIN_PY"
    echo "🔧 تم تحديث سطر fastapi import لإضافة Query"
  else
    # لو مفيش السطر ده أصلاً، نضيف واحد في أعلى الملف
    sed -i '1i from fastapi import FastAPI, HTTPException, Query' "$MAIN_PY"
    echo "🔧 تم إضافة سطر import جديد لـ FastAPI/HTTPException/Query في أعلى الملف"
  fi
fi

# 3) إضافة الـ endpoint إذا لم يكن موجودًا
if grep -q "async def analyze_message" "$MAIN_PY"; then
  echo "ℹ️ endpoint analyze_message موجود بالفعل، لن يتم تكراره"
else
  cat >> "$MAIN_PY" << 'EOPY'

# ===== التحليل الذكي لرسائل المستخدمين باستخدام LLMOrchestrator =====
@app.get("/api/orchestrator/analyze")
async def analyze_message(
    message: str = Query(..., description="نص رسالة المستخدم"),
    user_id: str = Query("anonymous", description="معرّف المستخدم"),
):
    """
    تحليل الرسالة وتحديد العامل المناسب (Debug / Architect / Coach / Spider)
    مع سبب الاختيار.
    """
    try:
        import sys
        sys.path.append("/root/hyper-factory/scripts/ai/llm")
        from llm_orchestrator import LLMOrchestrator
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"فشل في تحميل LLMOrchestrator: {str(e)}",
        )

    try:
        orchestrator = LLMOrchestrator()
        analysis = orchestrator.analyze_message(message, user_id)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"فشل في تحليل الرسالة: {str(e)}",
        )

    return {
        "success": True,
        "user_id": user_id,
        "message": message,
        "target_agent": analysis.get("target_agent"),
        "confidence": analysis.get("confidence"),
        "reason": analysis.get("reason"),
    }
EOPY

  echo "✅ تم إضافة endpoint /api/orchestrator/analyze إلى main.py"
fi

# 4) إعادة تشغيل الخدمة عبر ffactory.sh
cd "$BASE_DIR"
./scripts/core/ffactory.sh stop backend_coach || true
./scripts/core/ffactory.sh start backend_coach

echo "⏳ انتظار الإقلاع..."
sleep 5

echo "-- /api/health"
curl -s "http://localhost:9090/api/health" || true
echo
echo "-- /api/orchestrator/analyze (اختبار سريع)"
curl -s "http://localhost:9090/api/orchestrator/analyze?message=عندي%20خطأ%20في%20الكود&user_id=test_cli" || true
echo

echo "🎯 انتهى السكربت"
