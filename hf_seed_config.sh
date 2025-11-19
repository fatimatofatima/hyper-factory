#!/usr/bin/env bash
# hf_seed_config.sh - إنشاء ملفات إعداد أساسية لمصنع العمال الأذكياء

set -euo pipefail

ROOT="/root/hyper-factory"
CONFIG_DIR="$ROOT/config"

echo "📁 ROOT      : $ROOT"
echo "📂 CONFIG_DIR: $CONFIG_DIR"

mkdir -p "$CONFIG_DIR"

echo "📝 كتابة config/factory.yaml ..."
cat > "$CONFIG_DIR/factory.yaml" << 'YAML'
# factory.yaml - تعريف DataHome وبنية المصنع على الحديد

factory:
  name: "Hyper Factory"
  description: "مصنع العمال الأذكياء فوق بيانات اللعبة/الأنظمة."
  version: "0.1.0"

paths:
  root: "./"
  data_home: "./data"

  raw_dir: "./data/raw"
  processed_dir: "./data/processed"
  semantic_dir: "./data/semantic"
  serving_dir: "./data/serving"

  agents_root: "./ai/agents"
  pipelines_root: "./ai/pipelines"
  models_root: "./ai/models"
  experiments_root: "./ai/experiments"

  logs_dir: "./logs"
  reports_dir: "./reports"
  audit_dir: "./audit"

data_policies:
  keep_raw_forever: true
  delete_nothing: true
  versioned_processing: true

logging:
  level: "INFO"
  format: "json"
  rotation: "daily"

YAML

echo "📝 كتابة config/agents.yaml ..."
cat > "$CONFIG_DIR/agents.yaml" << 'YAML'
# agents.yaml - تعريف أولي لأنواع العمال (بدون تنفيذ فعلي)

agents:

  ingestor_basic:
    role: "ingestor"
    description: "عامل إدخال أولي - يسحب البيانات الخام إلى data/raw."
    enabled: true
    input:
      source_type: "filesystem"
      paths:
        - "./data/raw"
    output:
      path: "./data/raw"
    notes: "يتم دمجه لاحقًا مع سكربتات ingestion الحقيقية."

  processor_basic:
    role: "processor"
    description: "عامل معالجة - ينقل البيانات من raw إلى processed."
    enabled: true
    input:
      path: "./data/raw"
    output:
      path: "./data/processed"
    notes: "مسؤول عن التنظيف/التحويل التدريجي."

  analyzer_basic:
    role: "analyzer"
    description: "عامل تحليل - يبني تمثيل دلالي في data/semantic."
    enabled: true
    input:
      path: "./data/processed"
    output:
      path: "./data/semantic"
    notes: "يرتبط لاحقًا بوحدات الذكاء الاصطناعي."

  reporter_basic:
    role: "reporter"
    description: "عامل تقارير - يكتب مخرجات نهائية إلى data/serving و reports."
    enabled: true
    input:
      path: "./data/semantic"
    output:
      serving_path: "./data/serving"
      reports_path: "./reports"
    notes: "واجهة بين المصنع ولوحات العرض/الـ APIs."

orchestrator:
  enabled: false
  description: "يتم تفعيله لاحقًا لجدولة العمال بناءً على factory.yaml + agents.yaml."
  strategy: "sequential"
  notes: "هذه مجرد placeholder الآن."
YAML

echo "✅ تم إنشاء/تحديث:
  - $CONFIG_DIR/factory.yaml
  - $CONFIG_DIR/agents.yaml
بدون لمس أي ملفات أخرى."

