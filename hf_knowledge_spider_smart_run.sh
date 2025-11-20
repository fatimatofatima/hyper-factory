#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

KNOW_DB="$ROOT/data/knowledge/knowledge.db"
SPIDER_SH="$ROOT/hf_knowledge_spider.sh"
SPIDER_PY="$ROOT/hf_knowledge_spider.py"
REPORT_DIR="$ROOT/reports/knowledge"
mkdir -p "$REPORT_DIR"

echo "🕷 Hyper Factory – Knowledge Spider Smart Run"
echo "============================================"
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

echo "1) فحص سكربتات العنكبوت المعرفي:"
if [ -x "$SPIDER_SH" ]; then
  echo "   • hf_knowledge_spider.sh : موجود وقابل للتنفيذ"
elif [ -f "$SPIDER_SH" ]; then
  echo "   • hf_knowledge_spider.sh : موجود لكن غير قابل للتنفيذ (سأضبط الصلاحيات)"
  chmod +x "$SPIDER_SH"
elif [ -f "$SPIDER_PY" ]; then
  echo "   • hf_knowledge_spider.py : موجود وسيتم تشغيله عبر Python"
else
  echo "   ⚠️ لا يوجد hf_knowledge_spider.sh أو hf_knowledge_spider.py في الجذر."
  echo "   ⚠️ تخطّي خطوة التشغيل الفعلي، سيُعرض فقط وضع قاعدة المعرفة إن وُجدت."
fi
echo ""

echo "2) تشغيل العنكبوت (إن وُجد):"
if [ -x "$SPIDER_SH" ]; then
  echo "   ➜ تشغيل: ./hf_knowledge_spider.sh"
  if ./hf_knowledge_spider.sh; then
    echo "   ✔ انتهاء تشغيل hf_knowledge_spider.sh بنجاح."
  else
    echo "   ⚠️ hf_knowledge_spider.sh أنهى بخطأ (سيُستكمل الفحص على أي حال)."
  fi
elif [ -f "$SPIDER_PY" ]; then
  echo "   ➜ تشغيل: python3 hf_knowledge_spider.py"
  if python3 "$SPIDER_PY"; then
    echo "   ✔ انتهاء تشغيل hf_knowledge_spider.py بنجاح."
  else
    echo "   ⚠️ hf_knowledge_spider.py أنهى بخطأ (سيُستكمل الفحص على أي حال)."
  fi
else
  echo "   ℹ️ لا يوجد سكربت تشغيل، تم تخطّي هذه الخطوة."
fi
echo ""

echo "3) فحص قاعدة المعرفة knowledge.db:"
if [ ! -f "$KNOW_DB" ]; then
  echo "   ⚠️ قاعدة المعرفة غير موجودة: $KNOW_DB"
else
  echo "   ✔ قاعدة المعرفة موجودة."
  echo "   ▸ ملخص الجداول وعدد السجلات:"
  tables=$(sqlite3 "$KNOW_DB" ".tables" 2>/dev/null || true)
  if [ -z "$tables" ]; then
    echo "     (لا توجد جداول داخل قاعدة المعرفة.)"
  else
    printf "     %-24s %s\n" "table" "rows"
    printf "     ------------------------ -----\n"
    for t in $tables; do
      cnt=$(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM \"$t\";" 2>/dev/null || echo "?")
      printf "     %-24s %s\n" "$t" "$cnt"
    done
  fi

  SUMMARY_FILE="$REPORT_DIR/knowledge_db_overview_$(date -u +%Y%m%dT%H%M%SZ).txt"
  {
    echo "Knowledge DB Overview – $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "DB: $KNOW_DB"
    echo ""
    echo "Tables:"
    for t in $tables; do
      cnt=$(sqlite3 "$KNOW_DB" "SELECT COUNT(*) FROM \"$t\";" 2>/dev/null || echo "?")
      printf "  - %-24s %s\n" "$t" "$cnt"
    done
  } > "$SUMMARY_FILE"
  echo ""
  echo "   ✔ تم حفظ ملخص في: $SUMMARY_FILE"
fi
echo ""
echo "✅ Knowledge Spider Smart Run انتهى."
