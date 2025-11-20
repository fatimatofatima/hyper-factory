#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

DB_FACTORY="$ROOT/data/factory/factory.db"
DB_KNOW="$ROOT/data/knowledge/knowledge.db"
PATTERNS_TXT="$ROOT/reports/patterns/patterns_summary.txt"

echo "📊 Hyper Factory – Unified Control Room"
echo "======================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

echo "=== [A] Factory & Agents (factory.db) ==="
if [ -f "$DB_FACTORY" ] && [ -x "$ROOT/hf_factory_dashboard.sh" ]; then
  ./hf_factory_dashboard.sh || echo "⚠️ تعذر تشغيل hf_factory_dashboard.sh (محليًا)."
else
  echo "⚠️ لا يمكن عرض لوحة المصنع: إما factory.db مفقود أو hf_factory_dashboard.sh غير متاح."
fi

echo ""
echo "=== [B] Skills & Tracks (من factory.db) ==="
if [ -f "$DB_FACTORY" ]; then
  echo "▪ ملخص عدد المستخدمين في user_skills / user_tracks:"
  sqlite3 "$DB_FACTORY" "
    SELECT 'user_skills' AS table_name, COUNT(DISTINCT user_id) AS users FROM user_skills
    UNION ALL
    SELECT 'user_tracks', COUNT(DISTINCT user_id) FROM user_tracks;
  " 2>/dev/null | awk -F'|' 'BEGIN{
      printf "  %-14s %-10s\n","table","users";
      print  "  ----------------------";
    }{
      if (NF>1) printf "  %-14s %-10s\n",$1,$2;
    }'

  echo ""
  echo "▪ عينة صغيرة من user_tracks (بحد أقصى 5 صفوف):"
  sqlite3 "$DB_FACTORY" "
    SELECT user_id, track_id, current_phase, progress
    FROM user_tracks
    ORDER BY last_update DESC
    LIMIT 5;
  " 2>/dev/null | awk -F'|' 'BEGIN{
      printf "  %-10s %-24s %-20s %-8s\n","user","track","phase","progress";
      print  "  --------------------------------------------------------------";
    }{
      if (NF>1) printf "  %-10s %-24s %-20s %-8s\n",$1,$2,$3,$4;
    }'
else
  echo "⚠️ لا توجد قاعدة بيانات factory.db، تم تخطّي قسم المهارات."
fi

echo ""
echo "=== [C] Knowledge Spider / Knowledge DB ==="
if [ -f "$DB_KNOW" ]; then
  echo "▪ tables في knowledge.db:"
  tables=$(sqlite3 "$DB_KNOW" ".tables" 2>/dev/null || true)
  if [ -z "$tables" ]; then
    echo "  (لا توجد جداول داخل knowledge.db)"
  else
    printf "  %-24s %s\n" "table" "rows"
    printf "  ------------------------ -----\n"
    for t in $tables; do
      cnt=$(sqlite3 "$DB_KNOW" "SELECT COUNT(*) FROM \"$t\";" 2>/dev/null || echo "?")
      printf "  %-24s %s\n" "$t" "$cnt"
    done
  fi
else
  echo "⚠️ knowledge.db غير موجود، راجع hf_knowledge_spider_smart_run.sh."
fi

echo ""
echo "=== [D] Patterns & Quality Reports ==="
if [ -f "$PATTERNS_TXT" ]; then
  echo "▪ مقتطف من patterns_summary.txt (آخر 20 سطر):"
  tail -n 20 "$PATTERNS_TXT" || true
else
  echo "⚠️ لم يتم العثور على reports/patterns/patterns_summary.txt."
fi

if [ -d "$ROOT/reports/quality" ]; then
  echo ""
  echo "▪ ملفات الجودة المتاحة تحت reports/quality/:"
  ls -1 "$ROOT/reports/quality" 2>/dev/null || echo "  (لا توجد ملفات جودة حتى الآن)"
fi

echo ""
echo "✅ Unified Control Room جاهز."
