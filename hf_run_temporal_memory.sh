#!/bin/bash
set -e
ROOT="/root/hyper-factory"
cd "$ROOT" 2>/dev/null || {
  echo "❌ لا يمكن الدخول إلى $ROOT"
  exit 1
}
echo "🚀 تشغيل محرك الذاكرة الزمنية (Temporal Memory)..."
python3 agents/temporal_memory/main.py
