#!/usr/bin/env bash
# Hyper Factory – One-shot Status Snapshot (no loops, no sleep)
set -euo pipefail

ROOT="/root/hyper-factory"
DB_FACTORY="$ROOT/data/factory/factory.db"

cd "$ROOT" || exit 1

echo "=========================================="
echo " Hyper Factory – Status Snapshot"
echo " $(date '+%Y-%m-%d %H:%M:%S %z')"
echo "=========================================="

# حالة الـ Autopilot
PID_FILE="$ROOT/logs/24_7_autopilot.pid"
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo " Autopilot: RUNNING (PID $(cat "$PID_FILE"))"
else
    echo " Autopilot: NOT RUNNING"
fi

# آخر سطور من لوج الـ Autopilot
if [ -f "$ROOT/logs/hf_autopilot_full_power.log" ]; then
    echo
    echo "---- Last 20 lines from Autopilot log ----"
    tail -n 20 "$ROOT/logs/hf_autopilot_full_power.log" || true
fi

echo
echo "---- Factory Dashboard (control room) ----"
./hf_factory_dashboard.sh || echo " factory_dashboard: FAILED"

echo
echo "---- Unified Dashboard (AI / Agents KPIs) ----"
python3 tools/hf_unified_dashboard.py >/dev/null 2>&1 || true
if [ -f "$ROOT/reports/dashboard/unified_dashboard.txt" ]; then
    cat "$ROOT/reports/dashboard/unified_dashboard.txt"
else
    echo " unified_dashboard.txt not found."
fi

# ملخص سريع من performance_metrics (لو موجود)
if [ -f "$DB_FACTORY" ]; then
    echo
    echo "---- performance_metrics summary (top 10 agents) ----"
    sqlite3 "$DB_FACTORY" "
        SELECT agent_id, COUNT(*) AS cnt
        FROM performance_metrics
        GROUP BY agent_id
        ORDER BY cnt DESC
        LIMIT 10;
    " 2>/dev/null || true
fi

echo
echo "==== End of Snapshot ===="
