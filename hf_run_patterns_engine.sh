#!/bin/bash
set -e
ROOT="/root/hyper-factory"
cd "$ROOT" 2>/dev/null || {
  echo "❌ لا يمكن الدخول إلى $ROOT"
  exit 1
}
echo "🚀 تشغيل محرك الأنماط (Patterns Engine)..."
python3 agents/patterns_engine/main.py
