#!/bin/bash
set -e

ROOT="/root/hyper-factory"
cd "$ROOT"

echo "🩺 Hyper Factory - Crawler Health"
echo "================================="
echo "📍 المسار: $(pwd)"
echo "⏰ الوقت: $(date)"
echo

python3 scripts/fix_crawler_issues.py

echo
echo "✅ فحص وصيانة الزاحف اكتملت"
echo "📄 تقرير الصحة (إن وجد): reports/diagnostics/crawler_health_report.json"
