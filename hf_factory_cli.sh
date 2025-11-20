#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCH_PY="$ROOT/tools/hf_factory_orchestrator.py"
DB_INIT="$ROOT/hf_factory_db_init.sh"

usage() {
  cat << USAGE
Hyper Factory – Factory Manager CLI
===================================
استخدام:

  $0 init-db
      إنشاء/تحديث قاعدة بيانات المصنع (factory.db) + محاولة تحميل العمال والمهارات.

  $0 new "وصف المهمة" [priority]
      إنشاء مهمة جديدة (priority: low|normal|high, الافتراضي normal).

  $0 queue
      عرض المهام في حالة queued.

  $0 assign-next
      إسناد أول مهمة في الطابور queued إلى عامل مناسب وعرض أمر التنفيذ المقترح.
USAGE
}

cmd="$1"
if [ -z "$cmd" ]; then
  usage
  exit 1
fi
shift || true

case "$cmd" in
  init-db)
    "$DB_INIT"
    ;;
  new)
    desc="$1"
    prio="${2:-normal}"
    if [ -z "$desc" ]; then
      echo "⚠️ يجب تمرير وصف المهمة."
      usage
      exit 1
    fi
    python3 "$ORCH_PY" new-task "$desc" "$prio"
    ;;
  queue)
    python3 "$ORCH_PY" list-queue
    ;;
  assign-next)
    python3 "$ORCH_PY" assign-next
    ;;
  *)
    echo "⚠️ أمر غير معروف: $cmd"
    usage
    exit 1
    ;;
esac
