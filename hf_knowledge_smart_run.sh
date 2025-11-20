#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

DB_PATH="$ROOT/data/knowledge/knowledge.db"
SPIDER_SH="$ROOT/hf_knowledge_spider.sh"

echo "🤖 Hyper Factory – Knowledge Spider Smart Run"
echo "============================================"
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

echo "🔎 خطوة 1: فحص سريع لوضع عنكبوت المعرفة:"
if [ -x "$SPIDER_SH" ]; then
  echo "  ✔ hf_knowledge_spider.sh موجود وقابل للتنفيذ."
else
  echo "  ⚠️ hf_knowledge_spider.sh غير موجود أو غير قابل للتنفيذ."
fi
echo "  DB path: $DB_PATH"
echo ""

echo "🧱 خطوة 2: حالة قاعدة بيانات المعرفة:"
if [ -f "$DB_PATH" ]; then
  integrity="$(sqlite3 "$DB_PATH" 'PRAGMA integrity_check;' 2>/dev/null || echo 'error')"
  echo "  • integrity_check: $integrity"
  tables_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>/dev/null || echo 0)"
  echo "  • عدد الجداول: $tables_count"
else
  echo "  ⚠️ قاعدة البيانات غير موجودة بعد."
fi
echo ""

echo "📊 خطوة 3: Snapshot مختصر للجداول (إن وُجدت DB):"
if [ -f "$DB_PATH" ]; then
  tables=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
  if [ -z "$tables" ]; then
    echo "  (لا توجد جداول داخل قاعدة المعرفة)"
  else
    printf "  %-22s %-10s\n" "table" "rows"
    echo   "  -------------------------------"
    for t in $tables; do
      cnt=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM \"$t\";" 2>/dev/null || echo "?")
      printf "  %-22s %-10s\n" "$t" "$cnt"
    done
  fi
else
  echo "  (تم تخطي Snapshot لعدم وجود DB)"
fi
echo ""

echo "💡 خطوة 4: تذكير بالتشغيل الفعلي لعنكبوت المعرفة:"
if [ -x "$SPIDER_SH" ]; then
  echo "  ➜ يمكنك تشغيل عنكبوت المعرفة يدويًا مثلًا:"
  echo "     ./hf_knowledge_spider.sh"
  echo "     # أو أي أوامر/مفاتيح خاصة به كما ضبطناه سابقًا."
else
  echo "  ⚠️ يرجى التأكد من وجود hf_knowledge_spider.sh وضبطه قبل التشغيل الفعلي."
fi
echo ""

echo "✅ Knowledge Spider Smart Run اكتمل."
