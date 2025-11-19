#!/bin/bash
echo "🔍 فحص البنية المتقدمة لـ Hyper Factory..."
echo "⏰ الوقت: $(date)"
echo "📍 المسار: $(pwd)"
echo "👤 المستخدم: $(whoami)"
echo ""

# فحص النظام
echo "📊 حالة النظام:"
echo "---------------"
echo "💾 الذاكرة:"
free -h
echo ""
echo "💿 التخزين:"
df -h
echo ""
echo "🔥 وحدة المعالجة:"
lscpu | grep -E "^(CPU\(s\)|Model name|Architecture)"
echo ""
echo "🌐 الشبكة:"
ip addr show | grep inet | head -5
echo ""

# فحص العمليات
echo "🔄 العمليات النشطة:"
ps aux --sort=-%cpu | head -10
echo ""

# فحص السكريبتات
echo "📁 السكريبتات المتاحة:"
ls -la *.sh 2>/dev/null | head -10
echo ""

echo "✅ اكتمل فحص البنية المتقدمة"
