#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "🔄 Hyper Factory – Full Auto Cycle"
echo "=================================="
echo "⏰ $(date)"

# 1. فحص صحة النظام
echo "1. 🔍 فحص صحة النظام..."
./hf_factory_health_check.sh

# 2. إسناد المهام الجديدة
echo "2. 🎯 إسناد المهام الجديدة..."
./hf_factory_cli.sh assign-next

# 3. تنفيذ المهام المسندة
echo "3. 🚀 تنفيذ المهام المسندة..."
./hf_auto_executor.sh

# 4. تحديث الأداء
echo "4. 📈 تحديث أداء العمال..."
./hf_auto_performance_updater.sh

# 5. عرض النتائج
echo "5. 📊 عرض النتائج..."
./hf_factory_dashboard.sh

echo "✅ Full Auto Cycle اكتمل"
