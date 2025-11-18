#!/bin/bash
# init_factory.sh - الإصدار المصحح

set -e

BASE_DIR="$HOME/hyper-factory"
cd "$BASE_DIR"

echo "🚀 تهيئة مصنع العمال الأذكياء..."

# 1. جعل السكريبتات قابلة للتنفيذ
echo "🔧 جعل السكريبتات قابلة للتنفيذ..."
find scripts -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true

# 2. إنشاء ملفات التكوين الأساسية
echo "📄 إنشاء ملفات التكوين..."
mkdir -p config

# ملف المصنع الرئيسي
cat > config/factory_manifest.yaml << 'MANIFEST'
factory:
  id: hyper_factory_v1
  name: "مصنع العمال الأذكياء"
  owner: "root"
  environment: "production"
  version: "1.0.0"

orchestrator:
  decision_engine: "scripts/core/orchestrator_decision_engine.sh"
  rules_file: "config/orchestrator_rules.yaml"

agents:
  - debug_expert
  - system_architect  
  - technical_coach
  - knowledge_spider

knowledge_base:
  raw_dir: "ai/datasets/raw_content"
  cleaned_dir: "ai/datasets/cleaned_content" 
  chunks_dir: "ai/datasets/knowledge_chunks"
MANIFEST

# 3. التحقق من الاعتماديات
echo "🔍 التحقق من الاعتماديات..."
for cmd in docker python3 git curl; do
    if command -v "$cmd" &> /dev/null; then
        echo "   ✅ $cmd مثبت"
    else
        echo "   ❌ $cmd غير مثبت"
    fi
done

# 4. إنشاء ملفات السجل
echo "📝 إنشاء سجلات النظام..."
mkdir -p logs
touch logs/init.log
echo "$(date): تمت التهيئة بنجاح" >> logs/init.log

echo ""
echo "✅ التهيئة اكتملت بنجاح!"
echo "📍 المسار: $BASE_DIR"
