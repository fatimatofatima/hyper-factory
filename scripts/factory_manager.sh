#!/usr/bin/env bash
set -euo pipefail

# منطق توجيه ذكي للعوامل
route_to_agent() {
    local message="$1"
    
    # قواعد التوجيه
    if [[ "$message" == *"error"* ]] || [[ "$message" == *"traceback"* ]] || [[ "$message" == *"bug"* ]]; then
        echo "debug_expert"
    elif [[ "$message" == *"مشروع"* ]] || [[ "$message" == *"تصميم"* ]] || [[ "$message" == *"معماري"* ]]; then
        echo "system_architect"
    elif [[ "$message" == *"تعلم"* ]] || [[ "$message" == *"تدريب"* ]] || [[ "$message" == *"مسار"* ]]; then
        echo "technical_coach"
    elif [[ "$message" == *"بحث"* ]] || [[ "$message" == *"معلومة"* ]] || [[ "$message" == *"وثيقة"* ]]; then
        echo "knowledge_spider"
    else
        echo "debug_expert"  # افتراضي
    fi
}

# الاستخدام
AGENT=$(route_to_agent "$1")
echo "🔀 توجيه إلى: $AGENT"
./hf_run_${AGENT}.sh "$1"
