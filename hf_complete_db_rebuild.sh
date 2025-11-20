#!/bin/bash
# إعادة بناء قواعد البيانات بالكامل مع الحفاظ على البيانات

ROOT="/root/hyper-factory"
BACKUP_DIR="$ROOT/backup/db_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "🔧 بدء إعادة بناء قواعد البيانات..."

# نسخ احتياطي
cp "$ROOT/data/factory/factory.db" "$BACKUP_DIR/"
cp "$ROOT/data/knowledge/knowledge.db" "$BACKUP_DIR/"

# إعادة إنشاء الجداول مع الهيكل الصحيح
sqlite3 "$ROOT/data/factory/factory.db" <<'SQL'
-- حفظ البيانات المؤقتة
CREATE TEMPORARY TABLE tasks_backup AS SELECT * FROM tasks;
CREATE TEMPORARY TABLE agents_backup AS SELECT * FROM agents;

-- إسقاط الجداول
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS agents;

-- إعادة إنشاء tasks بالهيكل الصحيح
CREATE TABLE tasks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    created_at TEXT NOT NULL,
    source TEXT,
    description TEXT NOT NULL,
    task_type TEXT,
    type TEXT DEFAULT 'generic',
    family TEXT DEFAULT 'general',
    priority TEXT DEFAULT 'normal',
    status TEXT DEFAULT 'queued',
    agent_id TEXT,
    assigned_at TEXT,
    completed_at TEXT,
    result TEXT,
    error_message TEXT
);

-- إعادة إنشاء agents بالهيكل الصحيح
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

-- استعادة البيانات
INSERT INTO tasks SELECT 
    id, created_at, source, description, task_type, 
    COALESCE(type, 'generic') as type,
    COALESCE(family, 'general') as family,
    priority, status, NULL, NULL, NULL, NULL, NULL 
FROM tasks_backup;

INSERT INTO agents SELECT * FROM agents_backup;

-- تنظيف
DROP TABLE tasks_backup;
DROP TABLE agents_backup;
SQL

echo "✅ تم إعادة بناء factory.db"
