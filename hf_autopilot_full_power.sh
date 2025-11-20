#!/usr/bin/env bash
# Hyper Factory – 24/7 Full Power Autopilot (NO SLEEP)
set -euo pipefail

ROOT="/root/hyper-factory"
cd "$ROOT" || exit 1

echo "🚀 Hyper Factory – 24/7 Autopilot (MAX POWER, NO SLEEP)"

# حارس PID عشان ما يشتغلش مرتين
mkdir -p "$ROOT/logs" "$ROOT/run"
PID_FILE="$ROOT/logs/24_7_autopilot.pid"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "⚠️ Autopilot شغال بالفعل بـ PID $(cat "$PID_FILE")."
    exit 0
fi

echo $$ > "$PID_FILE"

run_step() {
    local cmd="$1"
    local label="$2"
    echo ""
    echo "▶️  [$label]"
    echo "    CMD: $cmd"
    if bash -c "$cmd"; then
        echo "✅  [$label] OK"
    else
        echo "⚠️  [$label] FAILED – مستمر في الدورة."
    fi
    return 0
}

while true; do
    echo "=================================================="
    echo "⏰ دورة Autopilot جديدة: $(date '+%Y-%m-%d %H:%M:%S %z')"
    echo "=================================================="

    # 1) خط الإنتاج الأساسي + دروس + تقارير مدير (hf_run_daily_ops)
    run_step "./hf_run_daily_ops.sh" \
        "خط الإنتاج + دروس + تقارير المدير"

    # 2) دورة تعلم سريع + تعزيز agents (debug_expert / system_architect / knowledge_spider / technical_coach)
    run_step "./hf_rapid_learning.sh" \
        "Rapid Learning Cycle"

    # 3) نظام القياس والتحكم الموحد (KPIs + Feedback + Unified Dashboard)
    run_step "./hf_unified_control_system.sh" \
        "Unified Control & Metrics"

    # 4) نشر وBoost لعوامل سبايدر المعرفة
    run_step "./hf_run_knowledge_spider_boost_1.sh" "Knowledge Spider Boost 1"
    run_step "./hf_run_knowledge_spider_boost_2.sh" "Knowledge Spider Boost 2"
    run_step "./hf_run_knowledge_spider_boost_3.sh" "Knowledge Spider Boost 3"
    run_step "./hf_run_knowledge_spider_boost_4.sh" "Knowledge Spider Boost 4"
    run_step "./hf_run_knowledge_spider_boost_5.sh" "Knowledge Spider Boost 5"
    run_step "./hf_run_knowledge_spider_boost_6.sh" "Knowledge Spider Boost 6"
    run_step "./hf_run_knowledge_spider_boost_7.sh" "Knowledge Spider Boost 7"

    # 5) جودة + اختبارات وتصنيف (Quality Engine)
    run_step "./hf_run_quality_engine_boost_1.sh" "Quality Engine Boost 1"
    run_step "./hf_run_quality_engine_boost_2.sh" "Quality Engine Boost 2"

    # 6) هندسة النظام (System Architect Boosts) – قرارات بنية وتشغيل
    run_step "./hf_run_system_architect_boost_1.sh" "System Architect Boost 1"
    run_step "./hf_run_system_architect_boost_2.sh" "System Architect Boost 2"
    run_step "./hf_run_system_architect_boost_3.sh" "System Architect Boost 3"

    # 7) تدريب وتعليم (Technical Coach Boosts)
    run_step "./hf_run_technical_coach_boost_1.sh" "Technical Coach Boost 1"
    run_step "./hf_run_technical_coach_boost_2.sh" "Technical Coach Boost 2"
    run_step "./hf_run_technical_coach_boost_3.sh" "Technical Coach Boost 3"
    run_step "./hf_run_technical_coach_boost_4.sh" "Technical Coach Boost 4"

    # 8) تحديث Dashboard المصنع (Control Room)
    run_step "./hf_factory_dashboard.sh" "Factory Dashboard (Control Room)"

    # 9) أنظمة Feedback وKPIs (لو موجودة)
    run_step "python3 tools/hf_feedback_system.py" \
        "Feedback System (KPS / Skills Feedback)"
    run_step "python3 tools/hf_performance_monitor.py" \
        "Performance Monitor (KPIs)"
    run_step "python3 tools/hf_unified_dashboard.py" \
        "Unified Dashboard Refresh"

    # لا يوجد أي sleep هنا – أقصى سرعة ممكنة
done
