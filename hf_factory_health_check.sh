#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

CLI_FACTORY="$ROOT/hf_factory_cli.sh"
CLI_SKILLS="$ROOT/hf_skills_cli.sh"
DASHBOARD="$ROOT/hf_factory_dashboard.sh"

echo "🩺 Hyper Factory – Factory Health Check"
echo "======================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo "📄 DB  : $DB_PATH"
echo ""

echo "🔎 فحص السكربتات الأساسية:"
printf "  %-28s : %s\n" "hf_factory_cli.sh"  "$( [ -x "$CLI_FACTORY" ] && echo '✅ موجود وقابل للتنفيذ' || echo '⚠️ مفقود أو غير قابل للتنفيذ' )"
printf "  %-28s : %s\n" "hf_skills_cli.sh"   "$( [ -x "$CLI_SKILLS" ] && echo '✅ موجود وقابل للتنفيذ' || echo '⚠️ مفقود أو غير قابل للتنفيذ' )"
printf "  %-28s : %s\n" "hf_factory_dashboard.sh" "$( [ -x "$DASHBOARD" ] && echo '✅ موجود وقابل للتنفيذ' || echo '⚠️ مفقود أو غير قابل للتنفيذ' )"
echo ""

if [ ! -f "$DB_PATH" ]; then
  echo "⚠️ قاعدة بيانات المصنع غير موجودة بعد."
  echo "   شغّل: ./hf_factory_cli.sh init-db"
  exit 0
fi

echo "🧱 فحص سلامة قاعدة البيانات (PRAGMA integrity_check):"
INTEGRITY=$(sqlite3 "$DB_PATH" "PRAGMA integrity_check;")
echo "  النتيجة: $INTEGRITY"
echo ""

echo "📊 حجم الجداول الأساسية:"
sqlite3 "$DB_PATH" "
SELECT 'agents'          AS table_name, COUNT(*) FROM agents
UNION ALL SELECT 'tasks',            COUNT(*) FROM tasks
UNION ALL SELECT 'task_assignments', COUNT(*) FROM task_assignments
UNION ALL SELECT 'skills',           COUNT(*) FROM skills
UNION ALL SELECT 'tracks',           COUNT(*) FROM tracks
UNION ALL SELECT 'track_phases',     COUNT(*) FROM track_phases
UNION ALL SELECT 'user_skills',      COUNT(*) FROM user_skills
UNION ALL SELECT 'user_tracks',      COUNT(*) FROM user_tracks;
" | awk -F'|' 'BEGIN{
  printf "  %-18s %-10s\n","table","rows";
  print  "  ---------------------------";
}{
  if (NF>1) {
    printf "  %-18s %-10s\n",$1,$2;
  }
}'
echo ""

echo "👷 عيّنة من العمال (agents) – حتى 5 فقط:"
sqlite3 "$DB_PATH" "
SELECT id,
       COALESCE(display_name,''),
       COALESCE(family,''),
       COALESCE(role,''),
       COALESCE(level,''),
       printf('%.2f', COALESCE(success_rate,0.0))
FROM agents
ORDER BY family, id
LIMIT 5;
" | awk -F'|' 'BEGIN{
  printf "  %-18s %-18s %-12s %-16s %-8s %-8s\n",
         "id","name","family","role","level","succ%";
  print  "  ----------------------------------------------------------------------";
}{
  if (NF>1) {
    printf "  %-18s %-18s %-12s %-16s %-8s %-8s\n",
           $1,$2,$3,$4,$5,$6;
  }
}'
echo ""

echo "📝 ملخص الحالات في جدول المهام (tasks):"
sqlite3 "$DB_PATH" "
SELECT status, COUNT(*) AS cnt
FROM tasks
GROUP BY status;
" | awk -F'|' 'BEGIN{
  printf "  %-12s %-10s\n","status","count";
  print  "  ----------------------";
}{
  if (NF>1) {
    printf "  %-12s %-10s\n",$1,$2;
  }
}'
echo ""

echo "🎯 تلميحات سريعة:"
AGENTS_CNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM agents;")
SKILLS_CNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM skills;")
TRACKS_CNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM tracks;")

if [ "$AGENTS_CNT" -eq 0 ]; then
  echo "  • ⚠️ لا يوجد أي عامل في جدول agents."
  echo "    - تأكد من وجود ai/memory/people/all_agents_complete.json"
  echo "    - ثم شغّل: ./hf_factory_cli.sh init-db"
fi

if [ "$SKILLS_CNT" -eq 0 ] || [ "$TRACKS_CNT" -eq 0 ]; then
  echo "  • ⚠️ نظام المهارات/المسارات غير مُحمّل بالكامل."
  echo "    - تأكد من وجود config/skills_tracks_backend_complete.yaml"
  echo "    - ثم شغّل: ./hf_skills_cli.sh init-skills"
fi

echo ""
echo "✅ فحص المصنع اكتمل."
