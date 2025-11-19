#!/bin/bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT" 2>/dev/null || {
  echo "❌ لا يمكن الدخول إلى $ROOT"
  exit 1
}

echo "🎓 Hyper Factory – Fix learning_system Offline-Loop"
echo "=================================================="

# التأكد من وجود learning_system
if [ -d "learning_system" ]; then
  echo "✅ DIR موجود: learning_system"
else
  mkdir -p "learning_system"
  echo "➕ تم إنشاء DIR: learning_system"
fi

# إنشاء Offline-Loop بما يتطابق مع فحص advanced_audit / hf_check_advanced_gaps
if [ -d "learning_system/Offline-Loop" ]; then
  echo "✅ DIR موجود: learning_system/Offline-Loop"
else
  mkdir -p "learning_system/Offline-Loop"
  cat > "learning_system/Offline-Loop/README.md" << 'RMD'
# Offline-Loop

هذا المجلد يمثل حلقة التعلم غير المتصل (Offline Learning Loop)
الخاصة بـ Hyper Factory.

- مسؤول عن:
  - تدريب الدُفعات (Batch Training)
  - تحليل التقارير التاريخية
  - تحديث أنظمة الأنماط والجودة بشكل غير متزامن

تم إنشاؤه تلقائيًا بواسطة hf_fix_learning_offline_loop.sh
كمكوّن هيكلي (Skeleton) فقط، بدون منطق تنفيذي بعد.
RMD
  echo "➕ تم إنشاء DIR: learning_system/Offline-Loop"
fi

echo
echo "✅ تم إصلاح فجوة Offline-Loop في learning_system (مستوى الهيكل فقط)."
