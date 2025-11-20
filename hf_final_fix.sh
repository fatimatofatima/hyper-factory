#!/bin/bash
echo "🔥 بدء الإصلاح النهائي السريع..."

# 1. إصلاح هيكل الجداول في factory.db
sqlite3 /root/hyper-factory/data/factory/factory.db <<'SQL'
-- إسقاط وإعادة إنشاء جدول agents بالهيكل الصحيح
DROP TABLE IF EXISTS agents;
CREATE TABLE agents (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    family TEXT,
    role TEXT,
    level TEXT,
    status TEXT DEFAULT 'active',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    last_seen TEXT,
    success_rate REAL DEFAULT 0.0,
    total_runs INTEGER DEFAULT 0
);

-- إدراج العوامل الأساسية
INSERT INTO agents (id, name, family, role, level) VALUES
('system_architect', 'مهندس النظام', 'architecture', 'architecture_design', 'advanced'),
('debug_expert', 'خبير التصحيح', 'debugging', 'deep_debugging', 'advanced'),
('knowledge_spider', 'جامع المعرفة', 'knowledge', 'knowledge_collection', 'intermediate'),
('technical_coach', 'مدرب تقني', 'training', 'technical_training', 'intermediate'),
('ingestor_basic', 'عامل إدخال البيانات', 'pipeline', 'data_ingestor', 'senior'),
('processor_basic', 'عامل معالجة البيانات', 'pipeline', 'data_processor', 'senior'),
('analyzer_basic', 'عامل التحليل الدلالي', 'pipeline', 'data_analyzer', 'senior'),
('reporter_basic', 'عامل التقارير والتقديم', 'pipeline', 'data_reporter', 'senior');
SQL

# 2. تشغيل النظام الأساسي بدون تعقيد
echo "✅ تم إصلاح قاعدة البيانات"
echo "🚀 تشغيل النظام الأساسي..."
./hf_run_system_architect.sh &
./hf_run_debug_expert.sh &
./hf_run_knowledge_spider.sh &

# 3. تشغيل المراقبة المبسطة
./hf_factory_dashboard.sh
