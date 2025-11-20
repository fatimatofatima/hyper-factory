#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

if [ ! -f "$DB_PATH" ]; then
  echo "⚠️ قاعدة بيانات المصنع غير موجودة: $DB_PATH"
  echo "   شغّل: ./hf_factory_cli.sh init-db"
  exit 1
fi

echo "📊 Hyper Factory – Control Room (Dashboard)"
echo "==========================================="
echo "⏰ $(date)"
echo "📁 DB: $DB_PATH"
echo ""

echo "👷 العمال (agents):"
sqlite3 "$DB_PATH" "
  SELECT
    id,
    COALESCE(display_name, ''),
    COALESCE(family, ''),
    COALESCE(role, ''),
    COALESCE(level, ''),
    printf('%.2f', COALESCE(success_rate,0.0)),
    COALESCE(total_runs,0)
  FROM agents
  ORDER BY family, id;
" | awk -F'|' 'BEGIN{
  printf "  %-20s %-20s %-12s %-18s %-10s %-10s %-10s\n",
         "id","name","family","role","level","succ_rate","runs";
  print "  -------------------------------------------------------------------------------";
}{
  if (NF>1) {
    printf "  %-20s %-20s %-12s %-18s %-10s %-10s %-10s\n",
           $1,$2,$3,$4,$5,$6,$7;
  }
}'

echo ""
echo "📝 ملخص المهام حسب الحالة:"
sqlite3 "$DB_PATH" "
  SELECT status, COUNT(*) AS cnt
  FROM tasks
  GROUP BY status;
" | awk -F'|' 'BEGIN{
  printf "  %-12s %-10s\n","status","count";
  print "  ----------------------";
}{
  if (NF>1) {
    printf "  %-12s %-10s\n",$1,$2;
  }
}'

echo ""
echo "🎯 تعيينات المهام لكل عامل:"
sqlite3 "$DB_PATH" "
  SELECT agent_id, COUNT(*) AS cnt
  FROM task_assignments
  GROUP BY agent_id
  ORDER BY cnt DESC;
" | awk -F'|' 'BEGIN{
  printf "  %-20s %-10s\n","agent_id","assignments";
  print "  ---------------------------";
}{
  if (NF>1) {
    printf "  %-20s %-10s\n",$1,$2;
  }
}'

echo ""
echo "✅ Dashboard جاهز."
