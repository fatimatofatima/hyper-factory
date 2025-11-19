#!/usr/bin/env bash
# Hyper Factory – Seed advanced agents config (ملف مستقل)
set -euo pipefail

ROOT="\${1:-/root/hyper-factory}"
cd "\$ROOT" 2>/dev/null || {
  echo "❌ ROOT غير موجود: \$ROOT"
  exit 1
}

mkdir -p config

TARGET="config/agents_advanced.yaml"

# عمل نسخة احتياطية إذا الملف موجود
if [ -f "\$TARGET" ]; then
  ts=\$(date +%Y%m%d%H%M%S)
  cp "\$TARGET" "\${TARGET}.\$ts.bak"
  echo "💾 Backup: \${TARGET}.\$ts.bak"
fi

cat > "\$TARGET" << 'YAML'
# Hyper Factory – Advanced Agents Config
# ملف مستقل للعوامل المتقدمة (لا يلمس agents.yaml)
# يمكن تضمينه يدويًا لاحقًا من orchestrator / factory إذا رغبت.

agents:
  - id: debug_expert
    family: advanced
    role: debug_expert
    display_name: "عامل تصحيح الأخطاء"
    enabled: false
    entrypoint:
      script: "hf_run_debug_expert.sh"
    description: >
      عامل متخصص في تحليل سجلات Hyper Factory، تتبع الأخطاء،
      واقتراح إصلاحات على مستوى السكربتات وخط الإنتاج.
    tags: ["advanced", "debug", "quality", "factory"]

  - id: system_architect
    family: advanced
    role: system_architect
    display_name: "عامل التصميم المعماري"
    enabled: false
    entrypoint:
      script: "hf_run_system_architect.sh"
    description: >
      عامل مسؤول عن مراجعة تصميم المصنع، توزيع الأدوار،
      ومقترحات إعادة الهيكلة وتوسعة البنية التحتية (data_lakehouse, factories, stack).
    tags: ["advanced", "architecture", "design", "factory"]

  - id: technical_coach
    family: advanced
    role: technical_coach
    display_name: "عامل التدريب"
    enabled: false
    entrypoint:
      script: "hf_run_technical_coach.sh"
    description: >
      عامل تدريب داخلي يقوم بقراءة الدروس (lessons) وجودة التشغيل،
      واقتراح خطط تطوير للعاملين (ingestor/processor/analyzer/reporter).
    tags: ["advanced", "coaching", "learning", "kpi"]

  - id: knowledge_spider
    family: advanced
    role: knowledge_spider
    display_name: "عامل جمع المعرفة"
    enabled: false
    entrypoint:
      script: "hf_run_knowledge_spider.sh"
    description: >
      عامل مسؤول عن الزحف داخل تقارير Hyper Factory وقاعدة المعرفة،
      وتجميع رؤوس موضوعات وأنماط يمكن تحويلها إلى دروس/توصيات.
    tags: ["advanced", "knowledge", "spider", "memory"]

YAML

echo "✅ تم إنشاء/تحديث config/agents_advanced.yaml (ملف مستقل)."
echo "ℹ️ الربط مع بقية النظام يتم يدويًا من orchestrator/factory عند الحاجة."
