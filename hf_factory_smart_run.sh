#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

DB_PATH="$ROOT/data/factory/factory.db"
CLI_FACTORY="$ROOT/hf_factory_cli.sh"
CLI_SKILLS="$ROOT/hf_skills_cli.sh"
DASHBOARD="$ROOT/hf_factory_dashboard.sh"
SKILLS_YAML="$ROOT/config/skills_tracks_backend_complete.yaml"

echo "🤖 Hyper Factory – Smart Run"
echo "============================"
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

if [ ! -x "$CLI_FACTORY" ]; then
  echo "❌ hf_factory_cli.sh غير موجود أو غير قابل للتنفيذ."
  exit 1
fi

echo "🧱 خطوة 1: تهيئة قاعدة بيانات المصنع (إن لزم)..."
./hf_factory_cli.sh init-db

if [ ! -f "$DB_PATH" ]; then
  echo "❌ لم يتم العثور على $DB_PATH بعد init-db – إيقاف."
  exit 1
fi

echo ""
echo "📚 خطوة 2: تحميل المهارات والمسارات (إن توفّر YAML وكانت الجداول فارغة)..."
SKILLS_CNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM skills;")
TRACKS_CNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM tracks;")

if [ -f "$SKILLS_YAML" ] && [ -x "$CLI_SKILLS" ]; then
  if [ "$SKILLS_CNT" -eq 0 ] || [ "$TRACKS_CNT" -eq 0 ]; then
    echo "  ➜ جارٍ تحميل المهارات والمسارات من $SKILLS_YAML ..."
    ./hf_skills_cli.sh init-skills || echo "⚠️ فشل init-skills (تحذير فقط)."
  else
    echo "  ✔ جداول skills/tracks تحتوي بيانات بالفعل – لا حاجة لإعادة التحميل."
  fi
else
  echo "  ℹ️ إما ملف YAML أو hf_skills_cli.sh غير متوفرين – تخطّي تحميل المهارات."
fi

echo ""
echo "🧩 خطوة 3: التأكد من وجود عمال في جدول agents..."
AGENTS_CNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM agents;")
if [ "$AGENTS_CNT" -eq 0 ]; then
  echo "  ⚠️ لا يوجد أي عامل في agents – يمكن أن يستمر النظام لكن assign-next لن يجد عاملاً."
else
  echo "  ✔ عدد العمال في agents: $AGENTS_CNT"
fi

echo ""
echo "📝 خطوة 4: إنشاء مهام نموذجية فقط إذا لم يوجد طابور حالي..."
QUEUED_CNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM tasks WHERE status = 'queued';")
echo "  • عدد المهام في حالة queued حاليًا: $QUEUED_CNT"

if [ "$QUEUED_CNT" -eq 0 ]; then
  echo "  ➜ إنشاء 3 مهام نموذجية:"
  ./hf_factory_cli.sh new "هناك خطأ في النظام يحتاج تحليل" high       || true
  ./hf_factory_cli.sh new "مشروع جديد يحتاج تصميم معماري" normal      || true
  ./hf_factory_cli.sh new "ابني لي مسار تعلم برمجة متقدم" normal      || true
else
  echo "  ✔ يوجد طابور مهام قائم – لن نضيف مهام إضافية."
fi

echo ""
echo "📋 خطوة 5: عرض الطابور الحالي:"
./hf_factory_cli.sh queue || true

echo ""
echo "🎯 خطوة 6: محاولة إسناد مهمة واحدة على الأقل:"
./hf_factory_cli.sh assign-next || true

echo ""
echo "📊 خطوة 7: تشغيل لوحة تحكم المصنع:"
if [ -x "$DASHBOARD" ]; then
  ./hf_factory_dashboard.sh || true
else
  echo "  ⚠️ hf_factory_dashboard.sh غير موجود أو غير قابل للتنفيذ – تخطّي الـ Dashboard."
fi

echo ""
echo "✅ Smart Run اكتمل."
