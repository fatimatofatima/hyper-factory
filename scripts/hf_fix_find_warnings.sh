#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Hyper Factory – Find Usage Scanner"
echo "ROOT : $ROOT"
echo

if [ ! -d "$ROOT/scripts" ]; then
  echo "WARN : لا يوجد مجلد scripts في $ROOT"
  exit 0
fi

echo "1) جميع الأسطر التي تحتوي على 'find ' داخل scripts/*.sh:"
echo "---------------------------------------------------------"
grep -RIn --exclude-dir=".git" --include="*.sh" "find " "$ROOT/scripts" || echo "لا توجد أوامر find في السكربتات."
echo

echo "2) أسطر تحتوي find + -o (قد تُسبب تحذيرات إن لم تُغلق بأقواس):"
echo "---------------------------------------------------------------"
grep -RIn --exclude-dir=".git" --include="*.sh" "find " "$ROOT/scripts" 2>/dev/null \
  | grep " -o " || echo "لا توجد أنماط find مع '-o'."
echo

echo "ملاحظة:"
echo "هذا السكربت لا يعدّل شيئًا؛ هو أداة رصد فقط."
echo "يمكنك تعديل السكربتات يدويًا بناءً على النتائج أعلاه."
