#!/bin/bash
echo "🏗️  بناء الهيكل المفقود لـ Hyper Factory..."

# 1. العوامل المتقدمة
echo "🔧 إنشاء العوامل المتقدمة..."
mkdir -p agents/{debug_expert,system_architect,technical_coach,knowledge_spider}

# 2. نظام التعليقات
echo "💬 إنشاء نظام التعليقات..."
mkdir -p feedback/{good,bad,reasons}

# 3. نظام التقييم
echo "📊 إنشاء نظام التقييم..."
mkdir -p evaluation/test_suites

# 4. زحف المعرفة
echo "🕷️ إنشاء زحف المعرفة..."
mkdir -p crawler/{sources,processors,exporters}

# 5. قاعدة المعرفة
echo "🧠 تحسين قاعدة المعرفة..."
mkdir -p knowledge/{snippets,patterns,templates}

echo "✅ اكتمل بناء الهيكل المفقود!"
