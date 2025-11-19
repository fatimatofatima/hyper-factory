#!/bin/bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT" 2>/dev/null || {
  echo "❌ لا يمكن الدخول إلى $ROOT"
  exit 1
}

echo "🎓 Hyper Factory – Fix learning_system gaps"
echo "========================================="

# التأكد من وجود learning_system
if [ -d "learning_system" ]; then
  echo "✅ DIR موجود: learning_system"
else
  mkdir -p "learning_system"
  echo "➕ تم إنشاء DIR: learning_system"
fi

# إنشاء Online-Loop باسم مطابق لما يستخدمه hf_check_advanced_gaps
if [ -d "learning_system/Online-Loop" ]; then
  echo "✅ DIR موجود: learning_system/Online-Loop"
else
  mkdir -p "learning_system/Online-Loop"
  cat > "learning_system/Online-Loop/README.md" << 'RMD'
# Online-Loop

هذا المجلد يمثل حلقة التعلم المباشر (Online Learning Loop)
الخاصة بـ Hyper Factory.

تم إنشاؤه تلقائيًا بواسطة hf_fix_learning_system.sh
كمكوّن هيكلي (Skeleton) فقط، بدون منطق تنفيذي بعد.
RMD
  echo "➕ تم إنشاء DIR: learning_system/Online-Loop"
fi

echo
echo "✅ تم إصلاح فجوات learning_system (مستوى الهيكل فقط)."
