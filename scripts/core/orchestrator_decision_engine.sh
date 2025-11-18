#!/bin/bash
# orchestrator_decision_engine.sh

set -e

BASE_DIR="$HOME/hyper-factory"
LOGS_DIR="$BASE_DIR/logs"
mkdir -p "$LOGS_DIR/orchestrator"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOGS_DIR/orchestrator/decisions.log"
    echo "$1"
}

# المدير يقرر أي عامل يشتغل
decide_agent() {
    local message="$1"
    local user_id="$2"
    
    log "🧠 المدير يحلل الرسالة من $user_id: '$message'"
    
    # قاعدة 1: إذا فيها أخطاء → Debug
    if echo "$message" | grep -qiE "(error|خطأ|traceback|exception|bug|مشكلة|غلط)"; then
        log "🔧 توجيه لـ: Debug Expert"
        echo "debug_expert"
        return 0
    fi
    
    # قاعدة 2: إذا فيها تصميم نظام → Architect  
    if echo "$message" | grep -qiE "(مصنع|نظام|تصميم|معماري|مشروع|هندسة|architecture|design)"; then
        log "🏗️ توجيه لـ: System Architect"
        echo "system_architect" 
        return 0
    fi
    
    # قاعدة 3: إذا فيها تعلم أو تدريب → Coach
    if echo "$message" | grep -qiE "(تعلم|تدريب|مسار|مهارة|تدرب|كورس|تعليم|learn|train)"; then
        log "👨‍🏫 توجيه لـ: Technical Coach"
        echo "technical_coach"
        return 0
    fi
    
    # قاعدة 4: إذا فيها معرفة أو مصادر → Spider
    if echo "$message" | grep -qiE "(مصدر|كتاب|مقال|docs|وثيقة|معرفة|knowledge|جمع|معلومات)"; then
        log "🕸️ توجيه لـ: Knowledge Spider"
        echo "knowledge_spider"
        return 0
    fi
    
    # افتراضي: Debug
    log "🔧 افتراضي: Debug Expert"
    echo "debug_expert"
}

# نظام مراقبة الجودة
monitor_quality() {
    local agent_id="$1"
    local user_id="$2"
    local quality="$3"  # good/bad
    
    log "📊 مراقبة الجودة: عامل $agent_id، مستخدم $user_id، جودة: $quality"
    
    # تسجيل في ملف الجودة
    echo "$(date +'%Y-%m-%d %H:%M:%S'),$agent_id,$user_id,$quality" >> "$LOGS_DIR/quality_feedback.csv"
    
    # تحذير إذا 3 ردود سيئة متتالية
    local recent_bad=$(tail -n 10 "$LOGS_DIR/quality_feedback.csv" | grep "$agent_id,$user_id,bad" | wc -l)
    
    if [ "$recent_bad" -ge 3 ]; then
        log "⚠️  تحذير: عامل $agent_id حصل على 3 تقييمات سيئة متتالية من $user_id"
    fi
}

# التنفيذ الرئيسي
main() {
    case "${1:-}" in
        "decide")
            if [ -z "$2" ]; then
                echo "❌ الاستخدام: $0 decide \"رسالة المستخدم\" [user_id]"
                exit 1
            fi
            decide_agent "$2" "${3:-anonymous}"
            ;;
        "quality")
            if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
                echo "❌ الاستخدام: $0 quality <agent_id> <user_id> <good/bad>"
                exit 1
            fi
            monitor_quality "$2" "$3" "$4"
            ;;
        "status")
            echo "📈 حالة المدير:"
            echo "   - القرارات المسجلة: $(wc -l < "$LOGS_DIR/orchestrator/decisions.log" 2>/dev/null || echo 0)"
            echo "   - تقييمات الجودة: $(wc -l < "$LOGS_DIR/quality_feedback.csv" 2>/dev/null || echo 0)"
            ;;
        *)
            echo "🧠 مدير مصنع العمال الأذكياء"
            echo "الاستخدام:"
            echo "  $0 decide \"رسالة\" [user_id]  # اتخاذ قرار"
            echo "  $0 quality agent user good/bad # تسجيل جودة"
            echo "  $0 status                      # عرض الحالة"
            ;;
    esac
}

main "$@"
