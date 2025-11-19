#!/bin/bash
echo "🔍 التحقق من تطابق التكوين مع الريبو الفعلي..."
echo "=============================================="

# التحقق من وجود السكريبتات المذكورة في التكوين
echo "📋 السكريبتات الموجودة في الريبو:"
scripts_in_repo=$(find . -name "hf_run_*.sh" -o -name "run_*.sh" | sort)
echo "$scripts_in_repo"

echo ""
echo "🔧 المقارنة مع config/agents.yaml:"
mentioned_scripts=$(grep "script:" config/agents.yaml | cut -d'"' -f2)

for script in $mentioned_scripts; do
    if [ -f "$script" ]; then
        echo "✅ $script - موجود في الريبو"
    else
        echo "❌ $script - مذكور في التكوين لكن غير موجود"
    fi
done

echo ""
echo "📊 الإحصائيات النهائية:"
total_scripts=$(echo "$scripts_in_repo" | wc -l)
total_configured=$(grep -c "script:" config/agents.yaml)
echo "   السكريبتات في الريبو: $total_scripts"
echo "   السكريبتات في التكوين: $total_configured"

if [ $total_scripts -eq $total_configured ]; then
    echo "🎉 التكوين يطابق الريبو تماماً!"
else
    echo "⚠️  هناك فرق بين التكوين والواقع"
fi
