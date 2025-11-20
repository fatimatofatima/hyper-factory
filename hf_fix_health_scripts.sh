#!/usr/bin/env bash
set -Eeuo pipefail

echo "🔧 Hyper Factory - Health Scripts Fix"
echo "======================================"
echo

# 1. إصلاح السكربتات الصحية
echo "📝 1. إصلاح السكربتات الصحية المكسورة..."
chmod +x hf_comprehensive_health_check.sh
chmod +x hf_audit_advanced_infra.sh

# 2. إصلاح تحذيرات FIND
echo "🔍 2. إصلاح تحذيرات FIND..."
./hf_fix_find_warnings.sh

# 3. تنظيف Git
echo "🧹 3. تنظيف ضوضاء Git..."
./hf_clean_git_noise.sh

# 4. التحقق من النتائج
echo
echo "✅ التحقق من الإصلاحات:"
./hf_comprehensive_health_check.sh

echo
echo "🎯 جميع الإصلاحات اكتملت بنجاح!"
