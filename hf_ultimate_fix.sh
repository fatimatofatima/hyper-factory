#!/bin/bash
echo "🎯 الإصلاح الشامل النهائي..."

# 1. إصلاح هيكل جدول agents في factory.db
sqlite3 /root/hyper-factory/data/factory/factory.db <<'SQL'
-- إسقاط وإعادة إنشاء جدول agents بالكامل
DROP TABLE IF EXISTS agents;
CREATE TABLE agents (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    display_name TEXT,
    family TEXT,
    role TEXT,
    level TEXT,
    category TEXT,
    status TEXT DEFAULT 'active',
    script_path TEXT,
    config_file TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    last_seen TEXT,
    success_rate REAL DEFAULT 0.0,
    total_runs INTEGER DEFAULT 0,
    description TEXT
);

-- إدراج العوامل الأساسية مع display_name
INSERT INTO agents (id, name, display_name, family, role, level, category, description) VALUES
('system_architect', 'System Architect', 'مهندس النظام', 'architecture', 'architecture_design', 'advanced', 'advanced', 'مسؤول عن تصميم وهندسة النظام'),
('debug_expert', 'Debug Expert', 'خبير التصحيح', 'debugging', 'deep_debugging', 'advanced', 'advanced', 'مسؤول عن تحليل الأعطال وتتبع الأخطاء'),
('knowledge_spider', 'Knowledge Spider', 'جامع المعرفة', 'knowledge', 'knowledge_collection', 'intermediate', 'knowledge', 'مسؤول عن جمع المعرفة من المصادر'),
('technical_coach', 'Technical Coach', 'مدرب تقني', 'training', 'technical_training', 'intermediate', 'training', 'مسؤول عن التدريب التقني'),
('quality_engine', 'Quality Engine', 'محرك الجودة', 'quality', 'quality_assurance', 'advanced', 'quality', 'مسؤول عن ضمان جودة النظام'),
('ingestor_basic', 'Data Ingestor', 'عامل إدخال البيانات', 'pipeline', 'data_ingestor', 'senior', 'pipeline', 'مسؤول عن إدخال البيانات'),
('processor_basic', 'Data Processor', 'عامل معالجة البيانات', 'pipeline', 'data_processor', 'senior', 'pipeline', 'مسؤول عن معالجة البيانات'),
('analyzer_basic', 'Data Analyzer', 'عامل التحليل الدلالي', 'pipeline', 'data_analyzer', 'senior', 'pipeline', 'مسؤول عن التحليل الدلالي'),
('reporter_basic', 'Data Reporter', 'عامل التقارير والتقديم', 'pipeline', 'data_reporter', 'senior', 'pipeline', 'مسؤول عن التقارير والتقديم');

-- تحديث task_assignments لربط المهام بالعوامل
UPDATE task_assignments SET agent_id = 'system_architect' WHERE agent_id = 'system_architect';
UPDATE task_assignments SET agent_id = 'debug_expert' WHERE agent_id = 'debug_expert';
UPDATE task_assignments SET agent_id = 'knowledge_spider' WHERE agent_id = 'knowledge_spider';
SQL

echo "✅ تم إصلاح هيكل قاعدة البيانات"

# 2. تشغيل العوامل الأساسية
echo "🚀 تشغيل العوامل الأساسية..."
./hf_run_debug_expert.sh &
./hf_run_system_architect.sh &
./hf_run_knowledge_spider.sh &
./hf_run_technical_coach.sh &
./hf_run_quality_engine.sh &

# 3. انتظر قليلاً ثم تحقق
sleep 0.1
echo "📊 التحقق من النتائج..."
./hf_factory_dashboard.sh
