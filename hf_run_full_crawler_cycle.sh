#!/bin/bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "🚀 Hyper Factory - Full Crawler Cycle"
echo "====================================="
echo "📍 المسار: $(pwd)"
echo "⏰ الوقت: $(date)"
echo

echo "1) 🩺 فحص صحة الزاحف..."
python3 scripts/fix_crawler_issues.py
echo

echo "2) 🕷️ تشغيل الزاحف المحسن..."
python3 tools/hf_web_spider_optimized.py
echo

echo "3) 📡 توليد تقرير إدارة الزواحف..."
python3 tools/hf_crawler_manager.py
echo

echo "✅ الدورة الكاملة للزاحف اكتملت بنجاح"
echo "📊 التقارير في:"
echo "   - reports/diagnostics/"
echo "   - reports/management/"
