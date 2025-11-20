#!/usr/bin/env bash
# Hyper Factory – Unified Control & Metrics System (Clean Version)
set -euo pipefail

ROOT="/root/hyper-factory"
DB_FACTORY="$ROOT/data/factory/factory.db"

echo "🎛️  تشغيل نظام القياس والتحكم الموحد..."

# 1) إنشاء هيكل الملفات
mkdir -p "$ROOT/ai/feedback" \
         "$ROOT/ai/performance" \
         "$ROOT/ai/monitoring" \
         "$ROOT/reports/dashboard"

# 2) ضمان وجود جداول القياس في factory.db
if [ -f "$DB_FACTORY" ]; then
    cat > /tmp/hf_unified_metrics.sql <<'SQL'
CREATE TABLE IF NOT EXISTS performance_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    metric_type TEXT NOT NULL,
    metric_value REAL NOT NULL,
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

CREATE TABLE IF NOT EXISTS feedback_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    metric_type TEXT,
    metric_value REAL,
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);
SQL

    sqlite3 "$DB_FACTORY" < /tmp/hf_unified_metrics.sql
else
    echo "⚠️ factory.db غير موجود: $DB_FACTORY"
fi

# 3) تشغيل أدوات القياس/اللوحة إن وُجدت
if [ -f "$ROOT/tools/hf_performance_monitor.py" ]; then
    python3 "$ROOT/tools/hf_performance_monitor.py" || echo "⚠️ فشل hf_performance_monitor.py"
fi

if [ -f "$ROOT/tools/hf_feedback_system.py" ]; then
    python3 "$ROOT/tools/hf_feedback_system.py" || echo "⚠️ فشل hf_feedback_system.py"
fi

if [ -f "$ROOT/tools/hf_unified_dashboard.py" ]; then
    python3 "$ROOT/tools/hf_unified_dashboard.py" || echo "⚠️ فشل hf_unified_dashboard.py"
fi

DASH="$ROOT/reports/dashboard/unified_dashboard.txt"

echo ""
if [ -f "$DASH" ]; then
    echo "📊 لوحة التحكم الموحدة:"
    cat "$DASH"
else
    echo "ℹ️ لم يتم إنشاء unified_dashboard.txt بعد."
fi

echo ""
echo "✅ تم تحديث قياسات الأداء والتحكم"
echo "✅ تم تحديث نظام التغذية الراجعة (إن وُجد)"
echo "✅ تم تحديث لوحة التحكم الموحدة"
