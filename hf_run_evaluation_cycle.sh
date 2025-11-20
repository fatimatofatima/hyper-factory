#!/bin/bash
echo "🔄 تشغيل دورة التقييم الموحدة..."

# 1. تشغيل محركات الجودة
./hf_run_quality_engine.sh
./hf_run_quality_engine_boost_1.sh
./hf_run_quality_engine_boost_2.sh

# 2. تشغيل محركات الأدوار والهيكلة
./hf_run_roles_engine.sh
./hf_run_schema_review.sh

# 3. تشغيل العقول المساندة
./hf_run_system_architect.sh
./hf_run_technical_coach.sh
./hf_run_temporal_memory.sh

# 4. تجميع النتائج
python3 tools/hf_evaluation_collector.py

echo "✅ اكتملت دورة التقييم"
