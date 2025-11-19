#!/bin/bash

# سكريبت لعرض تفاصيل محددة عن عامل معين

if [ $# -eq 0 ]; then
    echo "🔍 استخدام: $0 <اسم_العامل>"
    echo "   أمثلة:"
    echo "   $0 debug_expert"
    echo "   $0 system_architect" 
    echo "   $0 ingestor_basic"
    exit 1
fi

AGENT_NAME=$1

echo "🔎 تحليل مفصل للعامل: $AGENT_NAME"
echo "======================================"

# 1. البحث في التكوين
echo -e "\n📋 البحث في ملفات التكوين:"
if [ -f "config/agents.yaml" ]; then
    grep -A10 -B2 "$AGENT_NAME" config/agents.yaml | head -20
else
    echo "❌ config/agents.yaml غير موجود"
fi

# 2. البحث في السكريبتات
echo -e "\n🚀 البحث في سكريبتات التشغيل:"
find . -name "*$AGENT_NAME*" -type f 2>/dev/null | while read file; do
    echo "📄 $file"
    if [ -x "$file" ]; then
        echo "   ✅ قابل للتنفيذ"
    else
        echo "   ❌ غير قابل للتنفيذ"
    fi
done

# 3. البحث في العمليات النشطة
echo -e "\n🔥 البحث في العمليات النشطة:"
ps aux | grep -v grep | grep "$AGENT_NAME" | while read process; do
    echo "🟢 $process"
done

# 4. البحث في السجلات
echo -e "\n📊 البحث في السجلات:"
find . -name "*.log" -o -name "*.txt" -o -name "*.json" 2>/dev/null | \
    xargs grep -l "$AGENT_NAME" 2>/dev/null | head -5 | while read logfile; do
    echo "📁 $logfile"
    grep "$AGENT_NAME" "$logfile" | tail -3
done

# 5. عرض ملخص
echo -e "\n🎯 ملخص حالة العامل '$AGENT_NAME':"

config_exists=$(grep -c "$AGENT_NAME" config/agents.yaml 2>/dev/null || echo "0")
scripts_exist=$(find . -name "*$AGENT_NAME*" -type f 2>/dev/null | wc -l)
processes_running=$(ps aux | grep -v grep | grep -c "$AGENT_NAME" || echo "0")

echo "   📋 موجود في التكوين: $config_exists"
echo "   🚀 سكريبتات التشغيل: $scripts_exist"
echo "   🔥 عمليات نشطة: $processes_running"

if [ $processes_running -gt 0 ]; then
    echo "   🟢 العامل نشط ومشتغل"
elif [ $scripts_exist -gt 0 ]; then
    echo "   🟡 العامل موجود لكن غير نشط"
else
    echo "   🔴 العامل غير موجود"
fi
