#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

PATTERNS_SH="$ROOT/hf_run_patterns_engine.sh"
SUMMARY_JSON="$ROOT/ai/patterns/patterns_summary.json"
SUMMARY_TXT="$ROOT/reports/patterns/patterns_summary.txt"

echo "🤖 Hyper Factory – Quality & Patterns Smart Run"
echo "==============================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

echo "🔎 خطوة 1: فحص سريع لوجود محرك الأنماط:"
if [ -x "$PATTERNS_SH" ]; then
  echo "  ✔ hf_run_patterns_engine.sh موجود وقابل للتنفيذ."
else
  echo "  ⚠️ hf_run_patterns_engine.sh غير موجود أو غير قابل للتنفيذ."
fi
echo ""

echo "🚀 خطوة 2: تشغيل محرك الأنماط (إن وُجد):"
if [ -x "$PATTERNS_SH" ]; then
  "$PATTERNS_SH" || echo "  ⚠️ فشل تشغيل محرك الأنماط (تحذير فقط)."
else
  echo "  ⚠️ تم تخطي التشغيل لعدم توفر السكربت."
fi
echo ""

echo "📊 خطوة 3: Snapshot بعد التشغيل:"
if [ -f "$SUMMARY_TXT" ]; then
  echo "  • موجود reports/patterns/patterns_summary.txt"
  echo "    عيّنة (حتى 20 سطر):"
  head -n 20 "$SUMMARY_TXT" | sed 's/^/    /'
else
  echo "  ⚠️ لم يتم العثور على reports/patterns/patterns_summary.txt بعد التشغيل."
fi

if [ -f "$SUMMARY_JSON" ]; then
  size_bytes=$(stat -c '%s' "$SUMMARY_JSON" 2>/dev/null || wc -c < "$SUMMARY_JSON")
  echo ""
  echo "  • patterns_summary.json موجود – الحجم: ${size_bytes} bytes"
fi

echo ""
echo "✅ Quality & Patterns Smart Run اكتمل."
