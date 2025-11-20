#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT/logs/health"
REPORT_DIR="$ROOT/reports"

mkdir -p "$LOG_DIR" "$REPORT_DIR"

NOW="$(date +%Y-%m-%dT%H:%M:%S)"
LOG_FILE="$LOG_DIR/hf_health_${NOW//:/-}.log"

exec > >(tee -a "$LOG_FILE") 2>&1

section() {
  echo
  echo "════════════════════════════════════════════"
  echo "  $1"
  echo "════════════════════════════════════════════"
}

echo "Hyper Factory – Comprehensive Health Check"
echo "Time : $NOW"
echo "ROOT : $ROOT"
echo

section "1) الهيكل الأساسي (directories)"

for d in ai apps config logs reports scripts; do
  if [ -d "$ROOT/$d" ]; then
    echo "OK   : $d موجود"
  else
    echo "WARN : $d غير موجود"
  fi
done

section "2) أدوات النظام (python / pip)"

if command -v python3 >/dev/null 2>&1; then
  echo -n "python3 : "
  python3 -V || true
else
  echo "WARN : python3 غير مثبت"
fi

if command -v pip3 >/dev/null 2>&1; then
  echo -n "pip3    : "
  pip3 -V || true
else
  echo "WARN : pip3 غير مثبت"
fi

section "3) حالة قواعد البيانات (factory / knowledge)"

FACTORY_DB_DEFAULT="$ROOT/data/factory/factory.db"
KNOW_DB_DEFAULT="$ROOT/data/knowledge/knowledge.db"

FACTORY_DB="${FACTORY_DB:-$FACTORY_DB_DEFAULT}"
KNOWLEDGE_DB="${KNOWLEDGE_DB:-$KNOW_DB_DEFAULT}"

for db in "$FACTORY_DB" "$KNOWLEDGE_DB"; do
  if [ -e "$db" ]; then
    echo "DB OK : $db"
  else
    echo "INFO : لا يوجد ملف قاعدة بيانات حتى الآن -> $db"
  fi
done

section "4) حالة git داخل المستودع"

if command -v git >/dev/null 2>&1 && [ -d "$ROOT/.git" ]; then
  (
    cd "$ROOT"
    echo "Branch / حالة مختصرة:"
    git status -sb || true
  )
else
  echo "INFO : git غير متاح أو المستودع ليس git"
fi

section "5) فحص السكربتات (scripts/*.sh)"

if [ -d "$ROOT/scripts" ]; then
  echo "قائمة السكربتات (مع الصلاحيات):"
  find "$ROOT/scripts" -maxdepth 2 -type f -name "*.sh" -printf '%M %p\n' 2>/dev/null | sort || true
else
  echo "WARN : مجلد scripts غير موجود"
fi

section "6) ملخص نهائي"

echo "Log file : $LOG_FILE"
echo "Status   : الفحص الشامل اكتمل (مع تحذيرات إن وُجدت أعلاه)"

