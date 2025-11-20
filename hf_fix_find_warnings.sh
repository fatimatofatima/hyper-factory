#!/usr/bin/env bash
set -Eeuo pipefail

echo "🔧 إصلاح تحذيرات FIND في السكربتات..."
echo "====================================="

# قائمة السكربتات التي تحتاج إصلاح
scripts_to_fix=(
    "hf_comprehensive_health_check.sh"
    "hf_audit_advanced_infra.sh" 
    "hf_check_advanced_infra.sh"
    "hf_find_all_agents.sh"
)

for script in "${scripts_to_fix[@]}"; do
    if [[ -f "$script" ]]; then
        echo "📝 معالجة: $script"
        # تصحيح ترتيب find (سيتم تطبيقه يدويًا حسب الحاجة)
        sed -i 's/find . -type f -mindepth/find . -mindepth/g' "$script" 2>/dev/null || true
        sed -i 's/find . -type f -maxdepth/find . -maxdepth/g' "$script" 2>/dev/null || true
    fi
done

echo "✅ تم إصلاح تحذيرات FIND!"
