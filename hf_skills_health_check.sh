#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/factory/factory.db"

CLI_SKILLS="$ROOT/hf_skills_cli.sh"
SKILLS_PY="$ROOT/tools/hf_skills_engine.py"
SKILLS_YAML="$ROOT/config/skills_tracks_backend_complete.yaml"

echo "🩺 Hyper Factory – Skills & Tracks Health Check"
echo "==============================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo "📄 DB  : $DB_PATH"
echo ""

echo "🔎 فحص وجود الملفات الأساسية:"
printf "  %-32s : %s\n" "hf_skills_cli.sh"        "$( [ -x "$CLI_SKILLS" ] && echo '✅ موجود وقابل للتنفيذ' || echo '⚠️ مفقود أو غير قابل للتنفيذ' )"
printf "  %-32s : %s\n" "tools/hf_skills_engine.py" "$( [ -f "$SKILLS_PY" ] && echo '✅ موجود' || echo '⚠️ مفقود' )"
printf "  %-32s : %s\n" "skills_tracks YAML"      "$( [ -f "$SKILLS_YAML" ] && echo '✅ موجود' || echo '⚠️ غير موجود' )"
echo ""

if [ ! -f "$DB_PATH" ]; then
  echo "❌ قاعدة بيانات المصنع غير موجودة بعد."
  echo "   شغّل أولًا: ./hf_factory_cli.sh init-db"
  exit 1
fi

echo "🧱 فحص سلامة قاعدة البيانات (PRAGMA integrity_check):"
integrity="$(sqlite3 "$DB_PATH" 'PRAGMA integrity_check;')"
echo "  النتيجة: $integrity"
echo ""

echo "📊 حجم جداول المهارات والمسارات:"
sqlite3 "$DB_PATH" "
  SELECT 'skills' AS table_name, COUNT(*) AS cnt FROM skills
  UNION ALL
  SELECT 'tracks', COUNT(*) FROM tracks
  UNION ALL
  SELECT 'track_phases', COUNT(*) FROM track_phases
  UNION ALL
  SELECT 'user_skills', COUNT(*) FROM user_skills
  UNION ALL
  SELECT 'user_tracks', COUNT(*) FROM user_tracks;
" | awk -F'|' 'BEGIN{
  printf "  %-15s %-10s\n","table","rows";
  print  "  -------------------------";
}{
  if (NF>1) {
    printf "  %-15s %-10s\n",$1,$2;
  }
}'
echo ""

echo "👁 عيّنة من المهارات (حتى 5):"
sqlite3 "$DB_PATH" "
  SELECT id, name, category, level_min, level_max
  FROM skills
  ORDER BY id
  LIMIT 5;
" | awk -F'|' 'BEGIN{
  printf "  %-18s %-22s %-14s %-8s %-8s\n",
         "id","name","category","min","max";
  print  "  ---------------------------------------------------------------";
}{
  if (NF>1) {
    printf "  %-18s %-22s %-14s %-8s %-8s\n",$1,$2,$3,$4,$5;
  }
}'
echo ""

echo "📚 المسارات التدريبية (tracks):"
sqlite3 "$DB_PATH" "
  SELECT id, name, description
  FROM tracks
  ORDER BY id;
" | awk -F'|' 'BEGIN{
  printf "  %-22s %-26s %-40s\n","id","name","description";
  print  "  ---------------------------------------------------------------------------";
}{
  if (NF>1) {
    printf "  %-22s %-26s %-40s\n",$1,$2,$3;
  }
}'
echo ""

echo "📌 عيّنة مراحل أول مسار (track_phases):"
sqlite3 "$DB_PATH" "
  SELECT track_id, phase_order, name
  FROM track_phases
  ORDER BY track_id, phase_order
  LIMIT 10;
" | awk -F'|' 'BEGIN{
  printf "  %-22s %-8s %-30s\n","track_id","order","phase_name";
  print  "  --------------------------------------------------------";
}{
  if (NF>1) {
    printf "  %-22s %-8s %-30s\n",$1,$2,$3;
  }
}'
echo ""

echo "📈 ملخص تقدم المستخدمين (user_skills / user_tracks):"
sqlite3 "$DB_PATH" "
  SELECT 'user_skills' AS src, COUNT(DISTINCT user_id) AS users
  FROM user_skills
  UNION ALL
  SELECT 'user_tracks', COUNT(DISTINCT user_id)
  FROM user_tracks;
" | awk -F'|' 'BEGIN{
  printf "  %-15s %-12s\n","source","distinct_users";
  print  "  --------------------------";
}{
  if (NF>1) {
    printf "  %-15s %-12s\n",$1,$2;
  }
}'
echo ""

echo "✅ Skills & Tracks Health Check اكتمل."
