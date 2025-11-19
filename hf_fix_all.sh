#!/bin/bash
set -e

echo "🔧 Hyper Factory - Fix All"
echo "=========================="
echo "📍 المسار الحالي: $(pwd)"

# 1) إصلاح هيكل المجلدات
echo "📁 تهيئة المجلدات الأساسية..."
mkdir -p \
  reports/ai \
  reports/management \
  reports/diagnostics \
  reports/quality \
  reports/training \
  reports/architecture \
  ai/memory/training \
  ai/memory/curriculum \
  ai/memory/people \
  ai/memory/patterns \
  data/knowledge \
  logs/debug \
  logs/diagnostics \
  agents/debug_expert \
  agents/system_architect \
  agents/technical_coach \
  agents/knowledge_spider \
  scripts \
  config

# 2) إصلاح أذونات السكربتات
echo "🔐 ضبط أذونات السكربتات..."
find . -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null
find . -type f -name "*.py" -exec chmod +x {} \; 2>/dev/null

# 3) تحضير قاعدة المعرفة
if [ -f "tools/hf_prepare_knowledge_db.py" ]; then
  echo "🗄️ تحضير قاعدة المعرفة..."
  python3 tools/hf_prepare_knowledge_db.py || echo "⚠️ فشل تحضير قاعدة المعرفة (تابع يدويًا)"
else
  echo "⚠️ لم يتم العثور على tools/hf_prepare_knowledge_db.py (تجاوز الخطوة)"
fi

# 4) إصلاح ذاكرة Debug Expert
if [ -f "tools/repair_debug_memory.py" ]; then
  echo "🧠 إصلاح ذاكرة Debug Expert..."
  python3 tools/repair_debug_memory.py || echo "⚠️ فشل إصلاح ذاكرة Debug Expert (تجاوز)"
else
  echo "⚠️ لم يتم العثور على tools/repair_debug_memory.py (تجاوز الخطوة)"
fi

# 5) تشغيل مراقب الأخطاء (إن وجد)
if [ -f "tools/hf_error_monitor.py" ]; then
  echo "🛡️ تشغيل مراقب الأخطاء..."
  python3 tools/hf_error_monitor.py || echo "⚠️ فشل تشغيل مراقب الأخطاء (راجع logs/diagnostics)"
else
  echo "⚠️ لم يتم العثور على tools/hf_error_monitor.py (تجاوز الخطوة)"
fi

echo "✅ انتهى hf_fix_all.sh"
echo "📂 راجع التقارير في: reports/ و logs/diagnostics/"
