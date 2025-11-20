#!/usr/bin/env bash
set -Eeuo pipefail

# Hyper Factory – SQLite Lock Report
# يجمع إحصائيات عن رسائل "database is locked" من logs/*

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

if [ ! -d "$LOG_DIR" ]; then
  echo "❌ logs directory not found: $LOG_DIR"
  exit 1
fi

echo "📊 Hyper Factory – SQLite lock report"
echo "ROOT_DIR = $ROOT_DIR"
echo "LOG_DIR  = $LOG_DIR"
echo

# إجمالي عدد المرات
total=$(grep -R "database is locked" "$LOG_DIR" 2>/dev/null | wc -l || echo 0)
echo "🔢 إجمالي مرات ظهور 'database is locked': $total"
echo

echo "📁 أعلى الملفات تسببًا في الرسالة:"
grep -R "database is locked" "$LOG_DIR" 2>/dev/null \
  | sed 's/:.*database is locked.*/: database is locked/' \
  | cut -d: -f1 \
  | sort | uniq -c | sort -nr | head -20
echo

echo "🕒 أحدث 20 سطر فيها 'database is locked':"
grep -R "database is locked" "$LOG_DIR" 2>/dev/null | tail -20 || echo "لا توجد سجلات حديثة."
