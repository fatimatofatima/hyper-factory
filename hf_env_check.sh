#!/usr/bin/env bash
# hf_env_check.sh - فحص بيئة Hyper Factory (Python / pip / venv)

set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "📍 فحص البيئة في: $ROOT"
echo "----------------------------------------"

# Python
echo "🐍 Python:"
if command -v python3 >/dev/null 2>&1; then
  python3 --version
else
  echo "❌ python3 غير موجود في PATH"
fi
echo

# pip
echo "📦 pip:"
if command -v pip3 >/dev/null 2>&1; then
  pip3 --version
else
  echo "❌ pip3 غير موجود في PATH"
fi
echo

# virtualenv أو venv
echo "🧪 venv / virtualenv:"
if command -v virtualenv >/dev/null 2>&1; then
  echo "✅ virtualenv متوفر: $(command -v virtualenv)"
else
  echo "ℹ️ virtualenv غير موجود، سيتم الاعتماد على python -m venv لو احتجناه."
fi
echo

# مجلد venv داخل المشروع
if [[ -d "$ROOT/venv" ]]; then
  echo "✅ مجلد venv موجود تحت: $ROOT/venv"
else
  echo "ℹ️ لا يوجد venv محلي (venv/) داخل المشروع حتى الآن."
fi
echo

# backend_coach requirements
if [[ -d "$ROOT/apps/backend_coach" ]]; then
  echo "🧩 backend_coach:"
  if [[ -f "$ROOT/apps/backend_coach/requirements.txt" ]]; then
    echo "✅ requirements.txt موجود في apps/backend_coach/"
  else
    echo "ℹ️ لا يوجد requirements.txt في apps/backend_coach/"
  fi
else
  echo "ℹ️ مجلد apps/backend_coach غير موجود."
fi

echo
echo "✅ انتهى فحص البيئة (لم يتم تثبيت أي شيء، تقرير فقط)."

