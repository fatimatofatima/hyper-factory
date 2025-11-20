#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS_SH="$ROOT/hf_run_patterns_engine.sh"
SUMMARY_JSON="$ROOT/ai/patterns/patterns_summary.json"
SUMMARY_TXT="$ROOT/reports/patterns/patterns_summary.txt"

echo "🩺 Hyper Factory – Quality & Patterns Health Check"
echo "=================================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

echo "🔎 فحص وجود ملفات محرك الأنماط:"
printf "  %-36s : %s\n" "hf_run_patterns_engine.sh" "$( [ -x "$PATTERNS_SH" ] && echo '✅ موجود وقابل للتنفيذ' || echo '⚠️ مفقود أو غير قابل للتنفيذ' )"
printf "  %-36s : %s\n" "ai/patterns/patterns_summary.json" "$( [ -f "$SUMMARY_JSON" ] && echo '✅ موجود' || echo '⚠️ غير موجود' )"
printf "  %-36s : %s\n" "reports/patterns/patterns_summary.txt" "$( [ -f "$SUMMARY_TXT" ] && echo '✅ موجود' || echo '⚠️ غير موجود' )"
echo ""

if [ -f "$SUMMARY_JSON" ]; then
  size_bytes=$(stat -c '%s' "$SUMMARY_JSON" 2>/dev/null || wc -c < "$SUMMARY_JSON")
  echo "📄 patterns_summary.json:"
  echo "  • الحجم: ${size_bytes} bytes"
else
  echo "📄 patterns_summary.json: (غير متوفر)"
fi
echo ""

if [ -f "$SUMMARY_TXT" ]; then
  echo "📊 عيّنة من patterns_summary.txt (حتى 20 سطر):"
  head -n 20 "$SUMMARY_TXT" | sed 's/^/  /'
else
  echo "📊 patterns_summary.txt: (غير متوفر)"
fi

echo ""
echo "✅ Quality & Patterns Health Check اكتمل."
