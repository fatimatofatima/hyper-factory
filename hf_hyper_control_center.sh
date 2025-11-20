#!/bin/bash
set -e

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

FACTORY_HEALTH="$ROOT/hf_factory_health_check.sh"
FACTORY_DASH="$ROOT/hf_factory_dashboard.sh"
KNOW_HEALTH="$ROOT/hf_knowledge_health_check.sh"
QUALITY_HEALTH="$ROOT/hf_quality_health_check.sh"

echo "📌 Hyper Factory – Unified Control Center"
echo "========================================="
echo "⏰ $(date)"
echo "📍 ROOT: $ROOT"
echo ""

echo "🧱 1) فحص طبقة المصنع (Factory Manager / Skills / Tracks):"
if [ -x "$FACTORY_HEALTH" ]; then
  "$FACTORY_HEALTH"
else
  echo "  ⚠️ hf_factory_health_check.sh غير موجود أو غير قابل للتنفيذ."
fi
echo ""
echo "-----------------------------------------"
echo ""

echo "🕷 2) فحص عنكبوت المعرفة (Knowledge Spider):"
if [ -x "$KNOW_HEALTH" ]; then
  "$KNOW_HEALTH"
else
  echo "  ⚠️ hf_knowledge_health_check.sh غير موجود أو غير قابل للتنفيذ."
fi
echo ""
echo "-----------------------------------------"
echo ""

echo "📈 3) فحص جودة الأنماط (Quality & Patterns):"
if [ -x "$QUALITY_HEALTH" ]; then
  "$QUALITY_HEALTH"
else
  echo "  ⚠️ hf_quality_health_check.sh غير موجود أو غير قابل للتنفيذ."
fi
echo ""
echo "-----------------------------------------"
echo ""

echo "📊 4) لوحة تحكم المصنع (Factory Dashboard):"
if [ -x "$FACTORY_DASH" ]; then
  "$FACTORY_DASH"
else
  echo "  ⚠️ hf_factory_dashboard.sh غير موجود أو غير قابل للتنفيذ."
fi
echo ""
echo "✅ Unified Control Center اكتمل."
