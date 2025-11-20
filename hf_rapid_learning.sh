#!/usr/bin/env bash
# Hyper Factory – Rapid Learning Cycle (Clean, High-Speed)
set -euo pipefail

ROOT="/root/hyper-factory"
DB_FACTORY="$ROOT/data/factory/factory.db"
DB_KNOW="$ROOT/data/knowledge/knowledge.db"
DATE_TAG="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "🧠 Hyper Factory – Rapid Learning Cycle ($DATE_TAG)"

mkdir -p "$ROOT/ai/memory"

############################################
# 1) ضمان جاهزية knowledge_items + حقن دروس سريعة
############################################
if [ -f "$DB_KNOW" ]; then
    # إصلاح/ضبط مخطط knowledge_items (يضمن content)
    if [ -x "$ROOT/hf_fix_knowledge_schema.sh" ]; then
        "$ROOT/hf_fix_knowledge_schema.sh"
    fi

    echo "📚 تحديث knowledge.db (دروس تعلم سريع)..."
    sqlite3 "$DB_KNOW" <<'SQL'
INSERT INTO knowledge_items (title, content, category, source, created_at)
VALUES
('تعلم سريع – التصحيح',
 'تقنيات تصحيح سريعة وفعالة لعلاج مشاكل الأنظمة أثناء التشغيل.',
 'debugging',
 'rapid_learning',
 datetime('now')),

('تعلم سريع – هندسة النظام',
 'مبادئ تصميم الأنظمة المعقدة مع مراعاة الأداء والموثوقية والتوسع.',
 'architecture',
 'rapid_learning',
 datetime('now')),

('تعلم سريع – جمع المعرفة',
 'أساليب جمع وتحليل المعرفة التشغيلية من السجلات والأنظمة الحية.',
 'knowledge',
 'rapid_learning',
 datetime('now'));
SQL
else
    echo "⚠️ تخطي تحديث knowledge.db – الملف غير موجود: $DB_KNOW"
fi

############################################
# 2) ضخ قياسات أداء سريعة (KPIs) في factory.db
############################################
if [ -f "$DB_FACTORY" ]; then
    echo "📈 ضمان وجود جدول performance_metrics في factory.db..."
    sqlite3 "$DB_FACTORY" <<'SQL'
CREATE TABLE IF NOT EXISTS performance_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id    TEXT NOT NULL,
    metric_type TEXT NOT NULL,
    metric_value REAL NOT NULL,
    timestamp   TEXT DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);
SQL

    echo "📝 تسجيل boost جديد في performance_metrics..."
    sqlite3 "$DB_FACTORY" <<SQL
INSERT INTO performance_metrics (agent_id, metric_type, metric_value, description)
VALUES
('debug_expert',       'rapid_learning_boost', 1.0, 'Boost دورة تعلم سريع @ $DATE_TAG'),
('system_architect',   'rapid_learning_boost', 1.0, 'Boost دورة تعلم سريع @ $DATE_TAG'),
('knowledge_spider',   'rapid_learning_boost', 1.0, 'Boost دورة تعلم سريع @ $DATE_TAG'),
('technical_coach',    'rapid_learning_boost', 1.0, 'Boost دورة تعلم سريع @ $DATE_TAG');
SQL
else
    echo "⚠️ تخطي ضخ القياسات – factory.db غير موجود: $DB_FACTORY"
fi

############################################
# 3) تشغيل تدريب فعلي للعوامل الأساسية (تشغيل سكربتاتهم)
############################################
echo "🚀 تشغيل تدريب سريع للعوامل الأساسية..."

run_agent() {
    local script="$1"
    local label="$2"

    if [ -x "$ROOT/$script" ]; then
        echo "   ▶️  $label ..."
        "$ROOT/$script" || echo "   ⚠️ فشل تشغيل $label في هذه الدورة"
    else
        echo "   ⚠️ سكربت غير موجود أو غير قابل للتنفيذ: $script"
    fi
}

run_agent "hf_run_debug_expert_boost_1.sh"      "debug_expert boost 1"
run_agent "hf_run_system_architect_boost_1.sh"  "system_architect boost 1"
run_agent "hf_run_knowledge_spider_boost_1.sh"  "knowledge_spider boost 1"
run_agent "hf_run_technical_coach_boost_1.sh"   "technical_coach boost 1"

############################################
# 4) حفظ تقرير سريع في الذاكرة
############################################
REPORT="$ROOT/ai/memory/rapid_learning_report.json"
python3 - <<PY
import json, os, datetime
path = "$REPORT"
now = "$DATE_TAG"
data = {}
if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        data = {}
history = data.get("history", [])
history.append({"timestamp": now, "note": "rapid_learning_cycle_completed"})
data["history"] = history
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
PY

echo "✅ Rapid learning cycle completed (clean, high-speed)."
