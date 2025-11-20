#!/usr/bin/env bash
set -Eeuo pipefail

echo "🔍 Hyper Factory - Comprehensive Health Check"
echo "============================================"
echo "⏰ $(date '+%Y-%m-%d %H:%M:%S')"
echo

# تشغيل فحوصات الصحة الأساسية
echo "📊 1. Basic Health Check..."
./hf_health_check_fixed.sh

echo
echo "🏗️ 2. Infrastructure Check..."
./hf_check_advanced_infra.sh

echo
echo "🔍 3. Advanced Gaps Check..."
./hf_check_missing_advanced.sh

echo
echo "📈 4. System Performance..."
./hf_performance_dashboard.sh

echo
echo "✅ Comprehensive health check completed!"
echo "📊 View detailed reports in: reports/health/"
