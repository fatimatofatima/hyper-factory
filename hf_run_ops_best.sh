#!/bin/bash
set -e

ROOT="/root/hyper-factory"
BACKUP_DIR="/root/hf_backups"

cd "$ROOT" 2>/dev/null || {
  echo "❌ لا يمكن الدخول إلى $ROOT"
  exit 1
}

echo "🏭 Hyper Factory – Best Ops Runner"
echo "📍 ROOT = $ROOT"
echo "⏰ $(date)"
echo "==================================="

#######################################
# 1) السايكل المتقدمة (فحص + أنماط + جودة + ذاكرة زمنية)
#######################################
echo
echo "🔁 [1/3] تشغيل السايكل المتقدمة (hf_run_advanced_cycle.sh)..."
if [ -x "./hf_run_advanced_cycle.sh" ]; then
  ./hf_run_advanced_cycle.sh || echo "⚠️ hf_run_advanced_cycle.sh أنهى مع تحذير."
else
  echo "⚠️ hf_run_advanced_cycle.sh غير موجود أو غير قابل للتنفيذ."
fi

#######################################
# 2) مزامنة الكود مع GitHub
#######################################
echo
echo "🌐 [2/3] مزامنة الكود مع GitHub (hf_sync_code.sh)..."
if [ -x "./hf_sync_code.sh" ]; then
  ./hf_sync_code.sh || echo "⚠️ hf_sync_code.sh أنهى مع تحذير."
else
  echo "⚠️ hf_sync_code.sh غير موجود أو غير قابل للتنفيذ."
fi

#######################################
# 3) أخذ Snapshot Backup كامل
#######################################
echo
echo "🛡 [3/3] إنشاء Snapshot Backup (hf_backup_snapshot.sh)..."
if [ -x "./hf_backup_snapshot.sh" ]; then
  ./hf_backup_snapshot.sh || echo "⚠️ hf_backup_snapshot.sh أنهى مع تحذير."
else
  echo "⚠️ hf_backup_snapshot.sh غير موجود أو غير قابل للتنفيذ."
fi

#######################################
# 4) ملخص سريع لآخر النسخ الاحتياطية
#######################################
echo
echo "📦 آخر النسخ الاحتياطية في $BACKUP_DIR (إن وُجدت):"
echo "----------------------------------------------"

if [ -d "$BACKUP_DIR" ]; then
  ls -lh "$BACKUP_DIR" | tail -n 5
else
  echo "⚠️ مجلد الباكअप $BACKUP_DIR غير موجود."
fi

echo
echo "✅ Hyper Factory – Best Ops Cycle انتهت."
echo "⏰ $(date)"
