#!/usr/bin/env bash
# hf_backup_snapshot.sh
# إنشاء نسخة احتياطية كاملة من /root/hyper-factory في /root/hf_backups

set -euo pipefail

ROOT="/root/hyper-factory"
BACKUP_DIR="/root/hf_backups"

echo "============================================"
echo "🛡  Hyper Factory – Full Snapshot Backup"
echo "📁 PROJECT : ${ROOT}"
echo "📁 BACKUP  : ${BACKUP_DIR}"
echo "============================================"

mkdir -p "${BACKUP_DIR}"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
ARCHIVE_ZST="${BACKUP_DIR}/hyper-factory_full_${TS}.tar.zst"
ARCHIVE_GZ="${BACKUP_DIR}/hyper-factory_full_${TS}.tar.gz"

if command -v zstd >/dev/null 2>&1; then
  echo "📦 إنشاء أرشيف بصيغة Zstandard:"
  echo "   ${ARCHIVE_ZST}"
  tar -C /root -cf - hyper-factory | zstd -T0 -19 -o "${ARCHIVE_ZST}"
  FINAL="${ARCHIVE_ZST}"
else
  echo "📦 zstd غير متوفر – استخدام gzip:"
  echo "   ${ARCHIVE_GZ}"
  tar -C /root -czf "${ARCHIVE_GZ}" hyper-factory
  FINAL="${ARCHIVE_GZ}"
fi

echo "✅ تم إنشاء النسخة الاحتياطية بنجاح:"
ls -lh "${FINAL}"

echo "============================================"
echo "تم حفظ Snapshot كامل للوضع الحالي للمشروع."
echo "يمكنك نقل الملف أو نسخه إلى سيرفر آخر عند الحاجة."
echo "============================================"
