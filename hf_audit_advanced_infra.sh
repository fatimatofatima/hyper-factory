#!/usr/bin/env bash
set -Eeuo pipefail

echo "🔍 Hyper Factory - Advanced Infrastructure Audit"
echo "================================================"
echo "⏰ $(date '+%Y-%m-%d %H:%M:%S')"
echo

# فحص الهيكل المتقدم
echo "📁 1. Directory Structure Audit..."
find . -mindepth 1 -maxdepth 3 -type d -name "*agent*" -o -name "*factory*" | head -20

echo
echo "🔧 2. Scripts Health Check..."
find . -mindepth 1 -maxdepth 2 -type f -name "*.sh" -exec test -x {} \; -print | head -15

echo
echo "📊 3. Database Health..."
./hf_run_db_health.sh

echo
echo "✅ Advanced infrastructure audit completed!"
