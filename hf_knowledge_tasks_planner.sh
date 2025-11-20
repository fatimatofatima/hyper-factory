#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

DB_FACTORY="$ROOT/data/factory/factory.db"
DB_KNOW="$ROOT/data/knowledge/knowledge.db"
FACTORY_CLI="$ROOT/hf_factory_cli.sh"

echo "🧠 Hyper Factory – Knowledge Tasks Planner"
echo "=========================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

if [ ! -x "$FACTORY_CLI" ]; then
  echo "❌ hf_factory_cli.sh غير موجود أو غير قابل للتنفيذ."
  echo "   تأكد أنه موجود ثم أعد المحاولة."
  exit 1
fi

# 1) ضمان وجود قاعدة بيانات المصنع
if [ ! -f "$DB_FACTORY" ]; then
  echo "ℹ️ لا توجد factory.db – سيتم تشغيل init-db أولًا..."
  ./hf_factory_cli.sh init-db
fi

if [ ! -f "$DB_FACTORY" ]; then
  echo "❌ ما زالت factory.db غير موجودة بعد init-db – إيقاف."
  exit 1
fi

echo "1) فحص حجم طابور مهام المعرفة الحالى:"
queued_knowledge=$(sqlite3 "$DB_FACTORY" "SELECT COUNT(*) FROM tasks WHERE task_type='knowledge' AND status='queued';" 2>/dev/null || echo 0)
echo "   ▸ عدد مهام knowledge فى حالة queued حاليًا: $queued_knowledge"

# دالة مساعدة لإنشاء مهمة مرة واحدة فقط لكل Tag
ensure_task() {
  local tag="$1"
  local desc="$2"
  local prio="$3"

  local cnt
  cnt=$(sqlite3 "$DB_FACTORY" "SELECT COUNT(*) FROM tasks WHERE description LIKE '%#$tag%';" 2>/dev/null || echo 0)

  if [ "$cnt" -gt 0 ]; then
    echo "   • المهمة #$tag موجودة مسبقًا (count=$cnt) – لن نكررها."
  else
    echo "   ➜ إنشاء مهمة جديدة #$tag ..."
    ./hf_factory_cli.sh new "$desc #$tag" "$prio"
  fi
}

echo ""
echo "2) تقييم وضع قاعدة المعرفة (knowledge.db):"
if [ ! -f "$DB_KNOW" ]; then
  echo "   ⚠️ knowledge.db غير موجودة – سيتم إنشاء مهام تأسيس قاعدة معرفة."
  total_tables=0
  total_rows=0
else
  tables=$(sqlite3 "$DB_KNOW" ".tables" 2>/dev/null || true)
  if [ -z "$tables" ]; then
    total_tables=0
    total_rows=0
    echo "   ▸ knowledge.db موجودة لكن لا تحتوى على أى جداول."
  else
    total_tables=0
    total_rows=0
    for t in $tables; do
      cnt=$(sqlite3 "$DB_KNOW" "SELECT COUNT(*) FROM \"$t\";" 2>/dev/null || echo 0)
      total_rows=$(( total_rows + cnt ))
      total_tables=$(( total_tables + 1 ))
    done
    echo "   ▸ عدد الجداول: $total_tables"
    echo "   ▸ إجمالى السجلات (تقريبى): $total_rows"
  fi
fi

echo ""
echo "3) توليد مهام المعرفة/الجودة بناءً على الوضع:"

# حالة: لا يوجد DB أو فارغة تقريبًا
if [ "${total_tables:-0}" -eq 0 ] || [ "${total_rows:-0}" -lt 10 ]; then
  echo "   ▸ قاعدة المعرفة شبه فارغة – إنشاء مهام تأسيس وبناء أساسى."

  ensure_task "KF001" \
    "بناء قاعدة معرفة أساسية للمصنع (documentation, playbooks, architecture, incident reports, README) مع تنظيمها فى knowledge.db" \
    "high"

  ensure_task "KF002" \
    "جمع مصادر خارجية (research, knowledge) عن تصميم أنظمة Hyper Factory المشابهة وربطها فى قاعدة المعرفة" \
    "high"
else
  echo "   ▸ قاعدة المعرفة تحتوى بيانات – إنشاء مهام توسعة وتحسين."

  if [ "${total_rows:-0}" -lt 100 ]; then
    ensure_task "KF003" \
      "توسيع قاعدة المعرفة الحالية بإضافة السكربتات المهمة، تصميم البنية، وتقارير التشغيل اليومية (knowledge, docs)" \
      "normal"
  else
    ensure_task "KF004" \
      "مراجعة وتصنيف محتوى قاعدة المعرفة الحالية إلى فئات (patterns, quality, runbooks, howto) مع تنظيف التكرار" \
      "normal"
  fi
fi

# مهام جودة وأنماط تربط المعرفة بالـ Patterns Engine
ensure_task "KF010" \
  "تحليل تقارير الأنماط والجودة الأخيرة وربط كل Pattern مهم بمستند توثيق فى قاعدة المعرفة (patterns → knowledge)" \
  "normal"

ensure_task "KF011" \
  "إنشاء دليل 'أفضل الممارسات' بناءً على الأخطاء المتكررة والزلازل المسجّلة فى التقارير (quality, lessons learned)" \
  "normal"

echo ""
echo "4) ملخص بعد التخطيط:"
sqlite3 "$DB_FACTORY" "
  SELECT task_type, status, COUNT(*) AS cnt
  FROM tasks
  GROUP BY task_type, status
  ORDER BY task_type, status;
" 2>/dev/null | awk -F'|' 'BEGIN{
  printf "  %-12s %-10s %-6s\n","task_type","status","count";
  print  "  ---------------------------------";
}{
  if (NF>1) printf "  %-12s %-10s %-6s\n",$1,$2,$3;
}'

echo ""
echo "✅ Knowledge Tasks Planner انتهى."
