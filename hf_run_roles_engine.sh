#!/usr/bin/env bash
# hf_run_roles_engine.sh
# تشغيل Roles & Compensation Engine لحساب مستوى ورواتب الـ Agents

set -euo pipefail

ROOT="/root/hyper-factory"
SCRIPT="$ROOT/tools/hf_roles_engine.py"

echo "📁 ROOT   : $ROOT"
echo "📄 SCRIPT : $SCRIPT"
echo "----------------------------------------"

cd "$ROOT"

if ! command -v python3 >/dev/null 2>&1; then
  echo "❌ python3 غير متوفر في PATH."
  exit 1
fi

if [[ ! -f "$SCRIPT" ]]; then
  echo "❌ ملف hf_roles_engine.py غير موجود: $SCRIPT"
  exit 1
fi

python3 "$SCRIPT"
