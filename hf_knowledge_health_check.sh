#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_PATH="$ROOT/data/knowledge/knowledge.db"

SPIDER_SH="$ROOT/hf_knowledge_spider.sh"
SPIDER_PY="$ROOT/ai/knowledge/hf_knowledge_spider.py"

echo "🩺 Hyper Factory – Knowledge Spider Health Check"
echo "==============================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo "📄 DB  : $DB_PATH"
echo ""

echo "🔎 فحص وجود الملفات الأساسية:"
printf "  %-32s : %s\n" "hf_knowledge_spider.sh"   "$( [ -x "$SPIDER_SH" ] && echo '✅ موجود وقابل للتنفيذ' || echo '⚠️ مفقود أو غير قابل للتنفيذ' )"
printf "  %-32s : %s\n" "ai/knowledge/hf_knowledge_spider.py" "$( [ -f "$SPIDER_PY" ] && echo '✅ موجود' || echo '⚠️ مفقود' )"
echo ""

if [ ! -f "$DB_PATH" ]; then
  echo "⚠️ قاعدة بيانات المعرفة غير موجودة بعد."
  echo "   متوقع المسار: $DB_PATH"
  echo "   ➜ بعد ضبط عنكبوت المعرفة يمكنك إعادة تشغيل هذا الفحص."
  exit 0
fi

echo "🧱 فحص سلامة قاعدة بيانات المعرفة (PRAGMA integrity_check):"
integrity="$(sqlite3 "$DB_PATH" 'PRAGMA integrity_check;')"
echo "  النتيجة: $integrity"
echo ""

echo "📋 قائمة الجداول:"
tables=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
if [ -z "$tables" ]; then
  echo "  (لا توجد جداول داخل قاعدة المعرفة)"
else
  echo "$tables" | awk '{printf "  - %s\n",$1}'
fi
echo ""

echo "📊 حجم كل جدول (rows):"
if [ -n "$tables" ]; then
  printf "  %-22s %-10s\n" "table" "rows"
  echo   "  -------------------------------"
  for t in $tables; do
    cnt=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM \"$t\";" 2>/dev/null || echo "?")
    printf "  %-22s %-10s\n" "$t" "$cnt"
  done
else
  echo "  (لا توجد جداول لعرضها)"
fi
echo ""

# محاولات عرض جداول شائعة إن وُجدت
for t in sources documents pages notes; do
  exists=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='$t';")
  if [ "$exists" = "1" ]; then
    echo "📂 عيّنة من جدول $t:"
    sqlite3 "$DB_PATH" "SELECT * FROM $t LIMIT 5;" | sed 's/^/  /'
    echo ""
  fi
done

echo "✅ Knowledge Spider Health Check اكتمل."
