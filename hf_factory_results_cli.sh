#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_PY="$ROOT/tools/hf_factory_results.py"

usage() {
  cat << USAGE
Hyper Factory – Results & Quality CLI
=====================================
أوامر:

  $0 set-result <task_id> <success|fail> [notes...]
      تسجيل نتيجة مهمة + تحديث إحصائيات العامل تلقائيًا.

  $0 recompute-agents
      إعادة حساب إحصائيات جميع العمال من جدول task_assignments.

  $0 show-agents [agent_id]
      عرض إحصائيات كل العمال أو عامل محدد.
USAGE
}

cmd="$1"
if [ -z "$cmd" ]; then
  usage
  exit 1
fi
shift || true

case "$cmd" in
  set-result)
    if [ "$#" -lt 2 ]; then
      echo "⚠️ استخدام: $0 set-result <task_id> <success|fail> [notes...]"
      exit 1
    fi
    task_id="$1"
    status="$2"
    shift 2 || true
    python3 "$RESULTS_PY" set-result "$task_id" "$status" "$@"
    ;;
  recompute-agents)
    python3 "$RESULTS_PY" recompute-agents
    ;;
  show-agents)
    python3 "$RESULTS_PY" show-agents "$@"
    ;;
  *)
    echo "⚠️ أمر غير معروف: $cmd"
    usage
    exit 1
    ;;
esac
