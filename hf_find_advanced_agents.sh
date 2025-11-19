#!/usr/bin/env bash
# Hyper Factory – البحث عن العمال المتقدمين (debug_expert / system_architect / technical_coach / knowledge_spider)
set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT" 2>/dev/null || {
  echo "❌ لا يمكن الدخول إلى $ROOT"
  exit 1
}

AGENTS=("debug_expert" "system_architect" "technical_coach" "knowledge_spider")

echo "Hyper Factory – بحث عن العمال المتقدمين"
echo "ROOT: $ROOT"
echo "=========================================="
echo

for a in "${AGENTS[@]}"; do
  echo "=========================================="
  echo "👷 عامل: $a"
  echo "=========================================="

  # 1) مجلدات تحت agents/
  echo "- فحص مجلدات agents/${a}* ..."
  if compgen -G "agents/${a}*" > /dev/null; then
    ls -ld agents/${a}*
  else
    echo "  ▪ لا توجد مجلدات مطابقة في agents/${a}*"
  fi
  echo

  # 2) فحص ملفات الإعدادات الأساسية
  echo "- فحص ملفات الإعدادات:"
  for f in config/agents.yaml config/orchestrator.yaml config/factory.yaml ai/memory/people/agents_levels.json; do
    if [ -f "$f" ]; then
      if grep -q "$a" "$f"; then
        echo "  ▪ $f:"
        grep -n "$a" "$f"
      else
        echo "  ▪ $f: لا يوجد ذكر لـ $a"
      fi
    fi
  done
  echo

  # 3) البحث في سكربتات hf_*
  echo "- فحص سكربتات hf_*:"
  if ls hf_* >/dev/null 2>&1; then
    if grep -R -n "$a" hf_* >/dev/null 2>&1; then
      grep -R -n "$a" hf_* || true
    else
      echo "  ▪ لا يوجد ذكر لـ $a داخل hf_*"
    fi
  else
    echo "  ▪ لا توجد سكربتات hf_* في الجذر"
  fi
  echo

  # 4) البحث في tools/ (لو موجود)
  echo "- فحص مجلد tools/:"
  if [ -d tools ]; then
    if grep -R -n "$a" tools >/dev/null 2>&1; then
      grep -R -n "$a" tools || true
    else
      echo "  ▪ لا يوجد ذكر لـ $a داخل tools/"
    fi
  else
    echo "  ▪ لا يوجد مجلد tools/"
  fi

  echo
done

echo "------------------------------------------"
echo "✅ الفحص انتهى – راجع النتائج لكل عامل أعلاه."
