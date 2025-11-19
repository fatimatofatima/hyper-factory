#!/usr/bin/env bash
# hf_backend_smoke_test.sh - فحص جاف لتطبيق backend_coach (FastAPI) بدون تشغيل سيرفر

set -euo pipefail

ROOT="/root/hyper-factory"
APP_DIR="$ROOT/apps/backend_coach"

echo "📍 ROOT   : $ROOT"
echo "📂 APP_DIR: $APP_DIR"
echo "----------------------------------------"

if [[ ! -d "$APP_DIR" ]]; then
  echo "❌ مجلد apps/backend_coach غير موجود."
  exit 1
fi

cd "$APP_DIR"

# 1) التحقق من وجود requirements.txt (معلومة فقط)
if [[ -f "requirements.txt" ]]; then
  echo "✅ requirements.txt موجود."
else
  echo "ℹ️ لا يوجد requirements.txt (ليس خطأ، فقط ملاحظة)."
fi
echo

# 2) محاولة تحديد ملف الدخول (main/app)
ENTRY_FILE=""
for candidate in "main.py" "app.py" "backend.py"; do
  if [[ -f "$candidate" ]]; then
    ENTRY_FILE="$candidate"
    break
  fi
done

if [[ -z "$ENTRY_FILE" ]]; then
  echo "⚠️ لم أجد main.py أو app.py أو backend.py في $APP_DIR"
  echo "   هذا فقط smoke-test، تحتاج لاحقًا لتحديد ملف الدخول يدويًا."
  exit 0
fi

echo "📝 ملف الدخول المرشّح: $ENTRY_FILE"
echo

# 3) محاولة تجميع الملف (py_compile) للتأكد من عدم وجود أخطاء نحوية
echo "🧪 python3 -m py_compile $ENTRY_FILE"
if python3 -m py_compile "$ENTRY_FILE"; then
  echo "✅ تجميع Python نجح (لا توجد أخطاء syntax في $ENTRY_FILE)."
else
  echo "❌ فشل تجميع Python - راجع الأخطاء أعلاه."
  exit 1
fi

echo
echo "✅ Smoke test للـ backend_coach انتهى بنجاح (بدون تشغيل سيرفر)."

