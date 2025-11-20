#!/bin/bash
set -e

echo "🗄️ إعداد قاعدة بيانات المصنع (factory.db)"
echo "========================================="
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="$ROOT/data/factory"
DB_PATH="$DB_DIR/factory.db"

mkdir -p "$DB_DIR"

echo "📁 DB DIR : $DB_DIR"
echo "📄 DB PATH: $DB_PATH"

echo "🧱 إنشاء الجداول الأساسية (agents, tasks, task_assignments, skills, tracks)..."
sqlite3 "$DB_PATH" << 'SQL'
PRAGMA journal_mode=WAL;

-- عمال المصنع
CREATE TABLE IF NOT EXISTS agents (
  id TEXT PRIMARY KEY,
  family TEXT,
  role TEXT,
  display_name TEXT,
  level TEXT,
  salary_index REAL,
  success_rate REAL,
  total_runs INTEGER,
  success_runs INTEGER,
  failed_runs INTEGER,
  skills TEXT
);

-- المهام
CREATE TABLE IF NOT EXISTS tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at TEXT NOT NULL,
  source TEXT,
  description TEXT NOT NULL,
  task_type TEXT,
  priority TEXT DEFAULT 'normal',
  status TEXT DEFAULT 'queued'
);

-- تعيين المهام للعمال
CREATE TABLE IF NOT EXISTS task_assignments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL,
  agent_id TEXT NOT NULL,
  decision_reason TEXT,
  assigned_at TEXT NOT NULL,
  completed_at TEXT,
  result_status TEXT,
  result_notes TEXT,
  FOREIGN KEY(task_id) REFERENCES tasks(id),
  FOREIGN KEY(agent_id) REFERENCES agents(id)
);

-- تعريف المهارات
CREATE TABLE IF NOT EXISTS skills (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT,
  level_min INTEGER,
  level_max INTEGER,
  description TEXT
);

-- تعريف المسارات التدريبية
CREATE TABLE IF NOT EXISTS tracks (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT
);

-- مراحل كل مسار
CREATE TABLE IF NOT EXISTS track_phases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  track_id TEXT NOT NULL,
  phase_order INTEGER NOT NULL,
  name TEXT NOT NULL,
  FOREIGN KEY(track_id) REFERENCES tracks(id)
);

-- مستوى كل مستخدم في كل مهارة
CREATE TABLE IF NOT EXISTS user_skills (
  user_id TEXT NOT NULL,
  skill_id TEXT NOT NULL,
  level INTEGER NOT NULL,
  last_update TEXT NOT NULL,
  PRIMARY KEY(user_id, skill_id),
  FOREIGN KEY(skill_id) REFERENCES skills(id)
);

-- تقدم المستخدم في المسارات
CREATE TABLE IF NOT EXISTS user_tracks (
  user_id TEXT NOT NULL,
  track_id TEXT NOT NULL,
  current_phase TEXT,
  progress REAL DEFAULT 0.0,
  last_update TEXT NOT NULL,
  PRIMARY KEY(user_id, track_id),
  FOREIGN KEY(track_id) REFERENCES tracks(id)
);

CREATE INDEX IF NOT EXISTS idx_tasks_status_priority
  ON tasks(status, priority, created_at);

CREATE INDEX IF NOT EXISTS idx_assignments_task
  ON task_assignments(task_id);

CREATE INDEX IF NOT EXISTS idx_user_skills_user
  ON user_skills(user_id);

CREATE INDEX IF NOT EXISTS idx_user_tracks_user
  ON user_tracks(user_id);

SQL

echo "✅ تم إنشاء/تحديث مخطط قاعدة البيانات."

AGENTS_JSON="$ROOT/ai/memory/people/all_agents_complete.json"
ORCH_PY="$ROOT/tools/hf_factory_orchestrator.py"
SKILLS_ENGINE_PY="$ROOT/tools/hf_skills_engine.py"
SKILLS_YAML="$ROOT/config/skills_tracks_backend_complete.yaml"

# تحميل العمال من JSON إن أمكن
if [ -f "$AGENTS_JSON" ] && [ -f "$ORCH_PY" ]; then
  echo "👷 تحميل العمال من $AGENTS_JSON إلى قاعدة البيانات..."
  python3 "$ORCH_PY" init-agents || echo "⚠️ تعذر تحميل العمال (تحذير فقط)."
else
  echo "ℹ️ تخطّي تحميل العمال: ملف agents أو سكربت الأوركستريتور غير موجود حاليًا."
fi

# تحميل المهارات والمسارات من YAML إن أمكن
if [ -f "$SKILLS_YAML" ] && [ -f "$SKILLS_ENGINE_PY" ]; then
  echo "📚 تحميل تعريف المهارات والمسارات من $SKILLS_YAML..."
  python3 "$SKILLS_ENGINE_PY" init-skills || echo "⚠️ تعذر تحميل المهارات (تحذير فقط)."
else
  echo "ℹ️ تخطّي تحميل المهارات: ملف YAML أو سكربت المهارات غير موجود حاليًا."
fi

echo "📊 ملخص الجداول:"
sqlite3 "$DB_PATH" "SELECT 'agents' AS table_name, COUNT(*) AS cnt FROM agents
UNION ALL
SELECT 'tasks', COUNT(*) FROM tasks
UNION ALL
SELECT 'task_assignments', COUNT(*) FROM task_assignments
UNION ALL
SELECT 'skills', COUNT(*) FROM skills
UNION ALL
SELECT 'tracks', COUNT(*) FROM tracks
UNION ALL
SELECT 'track_phases', COUNT(*) FROM track_phases;"

echo "✅ قاعدة بيانات المصنع جاهزة."
