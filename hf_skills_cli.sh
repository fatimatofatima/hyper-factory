#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_INIT="$ROOT/hf_factory_db_init.sh"
SKILLS_PY="$ROOT/tools/hf_skills_engine.py"

usage() {
  cat << USAGE
Hyper Factory – Skills & Tracks CLI
===================================
أوامر:

  $0 init-db
      إنشاء/تحديث قاعدة البيانات (تتضمن جداول المهارات والمسارات).

  $0 init-skills
      تحميل المهارات والمسارات من config/skills_tracks_backend_complete.yaml.

  $0 set-skill <user_id> <skill_id> <level>
      ضبط مستوى مهارة لمستخدم.

  $0 set-track <user_id> <track_id> <current_phase> <progress>
      تحديث مسار مستخدم (phase + progress%).

  $0 show-user <user_id>
      عرض تقرير مهارات ومسارات مستخدم.
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
  init-skills)
    python3 "$SKILLS_PY" init-skills
    ;;
  set-skill)
    if [ "$#" -ne 3 ]; then
      echo "⚠️ استخدام: $0 set-skill <user_id> <skill_id> <level>"
      exit 1
    fi
    python3 "$SKILLS_PY" set-skill "$1" "$2" "$3"
    ;;
  set-track)
    if [ "$#" -ne 4 ]; then
      echo "⚠️ استخدام: $0 set-track <user_id> <track_id> <current_phase> <progress>"
      exit 1
    fi
    python3 "$SKILLS_PY" set-track "$1" "$2" "$3" "$4"
    ;;
  show-user)
    if [ "$#" -ne 1 ]; then
      echo "⚠️ استخدام: $0 show-user <user_id>"
      exit 1
    fi
    python3 "$SKILLS_PY" show-user "$1"
    ;;
  *)
    echo "⚠️ أمر غير معروف: $cmd"
    usage
    exit 1
    ;;
esac
