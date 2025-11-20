#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

DB_PATH="$ROOT/data/factory/factory.db"
CLI_FACTORY="$ROOT/hf_factory_cli.sh"
CLONE_PY="$ROOT/tools/hf_factory_clone_key_agents.py"

echo "👥 Hyper Factory – Multi-Agents Clone & Integration Planner"
echo "==========================================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

if [ ! -f "$DB_PATH" ]; then
  echo "🧱 factory.db غير موجود – محاولة init-db..."
  if [ -x "$CLI_FACTORY" ]; then
    "$CLI_FACTORY" init-db
  else
    echo "❌ hf_factory_cli.sh غير موجود أو غير قابل للتنفيذ."
    exit 1
  fi
fi

if [ ! -x "$CLONE_PY" ]; then
  echo "❌ tools/hf_factory_clone_key_agents.py غير موجود أو غير قابل للتنفيذ."
  exit 1
fi

python3 "$CLONE_PY"

echo ""
echo "✅ Clone & Integration planning finished."
