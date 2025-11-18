#!/bin/bash
# orchestrator.sh - المدير الذكي باستخدام الـ LLM

set -e

BASE_DIR="/root/hyper-factory"
LOG_FILE="$BASE_DIR/logs/orchestrator/decisions.log"
LLM_SCRIPT="$BASE_DIR/scripts/ai/llm/llm_orchestrator.py"

# إنشاء المجلدات إذا needed
mkdir -p "$(dirname "$LOG_FILE")"

# الألوان
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_decision() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local user="$1"
    local message="$2"
    local agent="$3"
    local reason="$4"
    
    echo -e "${timestamp} - 🧠 المدير يحلل الرسالة من ${user}: '${message}'" >> "$LOG_FILE"
    echo -e "${timestamp} - 💡 السبب: ${reason}" >> "$LOG_FILE"
    
    # رموز العمال
    case "$agent" in
        "debug_expert") echo -e "${timestamp} - 🔧 توجيه لـ: Debug Expert" >> "$LOG_FILE" ;;
        "system_architect") echo -e "${timestamp} - 🏗️ توجيه لـ: System Architect" >> "$LOG_FILE" ;;
        "technical_coach") echo -e "${timestamp} - 👨‍🏫 توجيه لـ: Technical Coach" >> "$LOG_FILE" ;;
        "knowledge_spider") echo -e "${timestamp} - 🕸️ توجيه لـ: Knowledge Spider" >> "$LOG_FILE" ;;
    esac
    
    echo -e "${timestamp} - 📊 الثقة: $5" >> "$LOG_FILE"
    echo "---" >> "$LOG_FILE"
}

decide() {
    local message="$1"
    local user_id="${2:-anonymous}"
    
    echo -e "${BLUE}🧠 المدير يحلل الرسالة من ${user_id}: '${message}'${NC}"
    
    # استخدام الـ LLM للتحليل الذكي
    if [ -f "$LLM_SCRIPT" ]; then
        cd "$BASE_DIR"
        source apps/backend_coach/venv/bin/activate
        
        # استدعاء مدير الـ LLM
        python3 -c "
import sys
sys.path.append('scripts/ai/llm')
from llm_orchestrator import smart_decide
result = smart_decide('$message', '$user_id')
print(result)
        " > /tmp/llm_result.txt
        
        AGENT=$(cat /tmp/llm_result.txt | tail -1)
        rm -f /tmp/llm_result.txt
    else
        # fallback إلى القواعد الأساسية
        message_lower=$(echo "$message" | tr '[:upper:]' '[:lower:]')
        if [[ $message_lower == *"خطأ"* || $message_lower == *"error"* || $message_lower == *"مشكلة"* ]]; then
            AGENT="debug_expert"
        elif [[ $message_lower == *"تصميم"* || $message_lower == *"هندسة"* || $message_lower == *"نظام"* ]]; then
            AGENT="system_architect" 
        elif [[ $message_lower == *"جمع"* || $message_lower == *"معلومات"* || $message_lower == *"بحث"* ]]; then
            AGENT="knowledge_spider"
        else
            AGENT="technical_coach"
        fi
    fi
    
    # تسجيل القرار
    log_decision "$user_id" "$message" "$AGENT" "تحليل آلي" "0.8"
    
    echo -e "${GREEN}✅ التوجيه لـ: $AGENT${NC}"
    echo "$AGENT"
}

# التنفيذ الرئيسي
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$1" = "decide" ] && [ -n "$2" ]; then
        user_id="${3:-anonymous}"
        decide "$2" "$user_id"
    else
        echo "استخدام: $0 decide \"الرسالة\" [معرف_المستخدم]"
        echo "مثال: $0 decide \"عندي خطأ في الكود\" user_123"
    fi
fi
