#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PHASE_KEY="$1"

echo "=================================================="
echo "🎯 Hyper Factory – تعيين مرحلة منهج نشطة (curriculum_phase)"
echo "ROOT      : $ROOT"
echo "PHASE_KEY : ${PHASE_KEY:-<not-provided>}"
echo "=================================================="

if [ -z "$PHASE_KEY" ]; then
  echo "Usage: $0 <phase_key_or_id>"
  echo "مثال:"
  echo "  $0 phase_stable_reference"
  echo "  $0 phase_scale_usage"
  exit 1
fi

if [ ! -f "$ROOT/data/knowledge/knowledge.db" ]; then
  echo "[ERROR] knowledge.db غير موجود: $ROOT/data/knowledge/knowledge.db"
  exit 1
fi

if [ ! -x "$ROOT/tools/hf_set_curriculum_phase.py" ]; then
  echo "[ERROR] سكربت Python غير موجود أو غير قابل للتنفيذ: tools/hf_set_curriculum_phase.py"
  exit 1
fi

python3 "$ROOT/tools/hf_set_curriculum_phase.py" "$PHASE_KEY"

echo "=================================================="
echo "✅ تم تنفيذ hf_run_set_phase.sh."
echo "راجع عناصر curriculum_phase داخل knowledge.db للتأكيد."
echo "=================================================="
