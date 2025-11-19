#!/bin/bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT" 2>/dev/null || {
  echo "❌ لا يمكن الدخول إلى $ROOT"
  exit 1
}

echo "🎓 Hyper Factory – Fix learning_system Curriculum"
echo "================================================"

if [ -d "learning_system" ]; then
  echo "✅ DIR موجود: learning_system"
else
  mkdir -p "learning_system"
  echo "➕ تم إنشاء DIR: learning_system"
fi

if [ -d "learning_system/Curriculum" ]; then
  echo "✅ DIR موجود: learning_system/Curriculum"
else
  mkdir -p "learning_system/Curriculum"
  cat > "learning_system/Curriculum/README.md" << 'RMD'
# Curriculum

هذا المجلد يمثل منهج التعلم (Curriculum) لنظام Hyper Factory:

- تعريف المسارات التعليمية (Tracks)
- مستويات المهارة (Beginner / Intermediate / Advanced)
- قواعد انتقال المعرفة بين الأنظمة (Patterns / Quality / Agents)

تم إنشاؤه تلقائيًا بواسطة hf_fix_learning_curriculum.sh
كمكوّن هيكلي فقط، بدون منطق تنفيذي بعد.
RMD
  echo "➕ تم إنشاء DIR: learning_system/Curriculum"
fi

echo
echo "✅ تم إصلاح فجوة Curriculum في learning_system (مستوى الهيكل فقط)."
