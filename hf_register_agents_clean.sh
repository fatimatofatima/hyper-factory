#!/bin/bash
# تسجيل العوامل من البداية باستخدام البيانات الفعلية

ROOT="/root/hyper-factory"
DB="$ROOT/data/knowledge/knowledge.db"

# إسقاط وإعادة إنشاء جدول agents
sqlite3 "$DB" "DROP TABLE IF EXISTS agents;"
sqlite3 "$DB" "CREATE TABLE agents (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
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
);"

# إدراج العوامل الأساسية من البيانات الفعلية
sqlite3 "$DB" <<'SQL'
INSERT INTO agents (id, name, family, role, level, category, script_path, description) VALUES
('system_architect', 'مهندس النظام', 'architecture', 'architecture_design', 'advanced', 'advanced', './hf_run_system_architect.sh', 'مسؤول عن تصميم وهندسة النظام'),
('debug_expert', 'خبير التصحيح', 'debugging', 'deep_debugging', 'advanced', 'advanced', './hf_run_debug_expert.sh', 'مسؤول عن تحليل الأعطال وتتبع الأخطاء'),
('knowledge_spider', 'جامع المعرفة', 'knowledge', 'knowledge_collection', 'intermediate', 'knowledge', './hf_run_knowledge_spider.sh', 'مسؤول عن جمع المعرفة من المصادر'),
('technical_coach', 'مدرب تقني', 'training', 'technical_training', 'intermediate', 'training', './hf_run_technical_coach.sh', 'مسؤول عن التدريب التقني'),
('ingestor_basic', 'عامل إدخال البيانات', 'pipeline', 'data_ingestor', 'senior', 'pipeline', './hf_run_ingestor_basic.sh', 'مسؤول عن إدخال البيانات'),
('processor_basic', 'عامل معالجة البيانات', 'pipeline', 'data_processor', 'senior', 'pipeline', './hf_run_processor_basic.sh', 'مسؤول عن معالجة البيانات'),
('analyzer_basic', 'عامل التحليل الدلالي', 'pipeline', 'data_analyzer', 'senior', 'pipeline', './hf_run_analyzer_basic.sh', 'مسؤول عن التحليل الدلالي'),
('reporter_basic', 'عامل التقارير والتقديم', 'pipeline', 'data_reporter', 'senior', 'pipeline', './hf_run_reporter_basic.sh', 'مسؤول عن التقارير والتقديم');
SQL

echo "✅ تم تسجيل $(sqlite3 "$DB" "SELECT COUNT(*) FROM agents;") عامل في knowledge.db"
