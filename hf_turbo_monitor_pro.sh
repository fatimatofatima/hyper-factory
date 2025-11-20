#!/usr/bin/env bash
set -Eeuo pipefail

DB="data/factory/factory.db"

if [[ ! -f "$DB" ]]; then
  echo "❌ قاعدة البيانات غير موجودة: $DB"
  exit 1
fi

last_done=-1
last_ts=0

while true; do
  clear
  now_ts=$(date +%s)
  now_human=$(date '+%H:%M:%S')

  echo "📊 TURBO MONITOR PRO - $now_human"
  echo "=========================================="

  echo "📋 حالة المهام:"
  sqlite3 "$DB" "SELECT status, COUNT(*) FROM tasks GROUP BY status;"

  echo
  echo "🎯 معدل الإنجاز:"
  sqlite3 "$DB" "SELECT printf('%.2f%%', COUNT(CASE WHEN status='done' THEN 1 END) * 100.0 / COUNT(*)) AS success_rate FROM tasks;"

  done_now=$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks WHERE status='done';")

  echo
  echo "👥 العوامل النشطة:"
  auto_count=$(ps aux | grep "hf_auto_executor.sh" | grep -v grep | wc -l)
  boost_count=$(ps aux | grep "hf_run_.*_boost_" | grep -v grep | wc -l)
  total_count=$(ps aux | grep -E "(hf_run_|hf_auto_executor)" | grep -v grep | wc -l)

  echo "- المنفذين التلقائيين: $auto_count"
  echo "- التعزيزات: $boost_count"
  echo "- إجمالي العمليات: $total_count"

  echo
  echo "⚡ سرعة الإنجاز التقريبية:"

  if (( last_done >= 0 )); then
    delta_done=$(( done_now - last_done ))
    delta_sec=$(( now_ts - last_ts ))
    if (( delta_sec > 0 )); then
      rate=$(( delta_done * 60 / delta_sec ))
      echo "- المهام/الدقيقة (آخر نافذة 10s تقريبًا): ~${rate}"
    else
      echo "- المهام/الدقيقة (آخر نافذة): ~0"
    fi
  else
    echo "- جاري قياس السرعة... (أول دورة)"
  fi

  last_done=$done_now
  last_ts=$now_ts

  sleep 10
done
