#!/bin/bash
set -e

REPO_PATH="/root/hyper-factory"
DB_PATH="$REPO_PATH/data/factory/factory.db"

echo "🔍 Hyper Factory – Infra Check"
echo "=============================="
echo "📁 REPO: $REPO_PATH"
echo "📄 DB  : $DB_PATH"
echo ""

if [ ! -d "$REPO_PATH" ]; then
    echo "❌ الريبو غير موجود: $REPO_PATH"
    exit 1
fi

#############################
# 1) فحص المجلدات الأساسية #
#############################

echo "📂 فحص المجلدات الأساسية:"
CORE_DIRS=(
  "agents"
  "ai"
  "apps"
  "data"
  "data/factory"
  "logs"
  "reports"
  "reports/factory"
  "reports/knowledge"
)

for d in "${CORE_DIRS[@]}"; do
  if [ -d "$REPO_PATH/$d" ]; then
    echo "  ✅ $d"
  else
    echo "  ❌ $d (مفقود)"
  fi
done

echo ""

#############################
# 2) فحص السكربتات الأساسية #
#############################

echo "🧾 فحص سكربتات المصنع الأساسية:"

CORE_SCRIPTS=(
  "hf_factory_cli.sh"
  "hf_skills_cli.sh"
  "hf_factory_health_check.sh"
  "hf_factory_dashboard.sh"
  "hf_full_auto_cycle.sh"
  "hf_factory_manager_daily.sh"
  "hf_auto_executor.sh"
  "hf_auto_performance_updater.sh"
  "hf_input_manager.sh"
  "hf_spiders_family.sh"
  "hf_quality_patterns_system.sh"
  "hf_resource_manager.sh"
  "hf_continuous_learning_loop.sh"
  "hf_sync_code.sh"
)

for s in "${CORE_SCRIPTS[@]}"; do
  if [ -f "$REPO_PATH/$s" ]; then
    if [ -x "$REPO_PATH/$s" ]; then
      echo "  ✅ $s (executable)"
    else
      echo "  ⚠️ $s موجود لكن غير قابل للتنفيذ (chmod +x)"
    fi
  else
    echo "  ❌ $s (مفقود)"
  fi
done

echo ""

#############################
# 3) فحص قاعدة بيانات المصنع #
#############################

echo "🗄️ فحص قاعدة بيانات المصنع:"
if [ ! -f "$DB_PATH" ]; then
  echo "  ❌ ملف DB غير موجود: $DB_PATH"
  echo ""
  echo "⛔ بقية فحوصات DB لن تعمل بدون قاعدة بيانات."
  exit 0
fi

echo "  ✅ ملف DB موجود"

echo ""
echo "🔎 PRAGMA integrity_check:"
sqlite3 "$DB_PATH" "PRAGMA integrity_check;" 2>/dev/null || echo "  ❌ مشكلة في فحص السلامة"

echo ""
echo "📋 الجداول الموجودة:"
TABLES=$(sqlite3 "$DB_PATH" ".tables" 2>/dev/null || echo "")
echo "  $TABLES"
echo ""

REQUIRED_TABLES=(
  "agents"
  "tasks"
  "task_assignments"
  "skills"
  "tracks"
  "track_phases"
  "user_skills"
  "user_tracks"
  "system_settings"
  "learning_log"
  "daily_reports"
)

echo "✅ / ❌ فحص الجداول الأساسية:"
for t in "${REQUIRED_TABLES[@]}"; do
  if echo "$TABLES" | tr ' ' '\n' | grep -qx "$t"; then
    echo "  ✅ $t"
  else
    echo "  ❌ $t (مفقود)"
  fi
done

echo ""
echo "📊 عيّنة من جدول agents (لو موجود):"
if echo "$TABLES" | tr ' ' '\n' | grep -qx "agents"; then
  sqlite3 "$DB_PATH" "
.headers on
.mode column
SELECT id, name, family, role, level, success_rate, total_runs
FROM agents
LIMIT 10;
" 2>/dev/null || echo "  ⚠️ مشكلة في قراءة agents"
else
  echo "  ⏭️ جدول agents غير موجود."
fi

echo ""
echo "📊 ملخص حالات المهام (لو جدول tasks موجود):"
if echo "$TABLES" | tr ' ' '\n' | grep -qx "tasks"; then
  sqlite3 "$DB_PATH" "
.headers on
.mode column
SELECT status, COUNT(*) AS count
FROM tasks
GROUP BY status;
" 2>/dev/null || echo "  ⚠️ مشكلة في قراءة tasks"
else
  echo "  ⏭️ جدول tasks غير موجود."
fi

echo ""
echo "✅ Hyper Factory – Infra Check انتهى"
