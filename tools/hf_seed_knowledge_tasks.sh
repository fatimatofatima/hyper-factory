#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="/root/hyper-factory"
DB="$ROOT_DIR/data/factory/factory.db"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "════════ Hyper Factory – Knowledge Tasks Seeder ════════"

if [[ ! -f "$DB" ]]; then
  log "❌ قاعدة البيانات غير موجودة: $DB"
  exit 1
fi

# قراءة مخطط جدول المهام ديناميكيًا
SCHEMA_RAW="$(sqlite3 "$DB" "PRAGMA table_info(tasks);" || true)"

if [[ -z "$SCHEMA_RAW" ]]; then
  log "❌ جدول tasks غير موجود في قاعدة البيانات"
  exit 1
fi

log "ℹ️  مخطط جدول tasks:"
printf '%s\n' "$SCHEMA_RAW" | awk -F'|' '{printf "   - %s (%s)\n", $2, $3}'

AVAILABLE_COLS="$(printf '%s\n' "$SCHEMA_RAW" | awk -F'|' '{print $2}')"

# مواضيع / مجالات المعرفة (تنويع قوي)
TOPICS=(
  "data"
  "databases"
  "devops"
  "linux"
  "networking"
  "security"
  "cloud"
  "kubernetes"
  "docker"
  "ai"
  "ml"
  "deep_learning"
  "nlp"
  "computer_vision"
  "android"
  "backend"
  "frontend"
  "python"
  "javascript"
  "go"
  "architecture"
  "microservices"
  "observability"
  "testing"
  "performance"
  "distributed_systems"
  "risk_management"
  "finance"
  "productivity"
)

# إدراج مهام معرفة لكل topic
insert_topic_task() {
  local topic="$1"

  local sql="INSERT INTO tasks ("
  local first=1

  # بناء قائمة الأعمدة
  for col in $AVAILABLE_COLS; do
    case "$col" in
      agent_id|type|status|description|priority|payload|tags|created_at|updated_at)
        if [[ $first -eq 0 ]]; then
          sql+=", "
        fi
        sql+="$col"
        first=0
        ;;
    esac
  done

  sql+=") VALUES ("
  first=1

  # بناء قائمة القيم بالترتيب نفسه
  for col in $AVAILABLE_COLS; do
    local val=""
    case "$col" in
      agent_id)
        val="'knowledge_spider'"
        ;;
      type)
        val="'knowledge'"
        ;;
      status)
        val="'queued'"
        ;;
      priority)
        val="5"
        ;;
      description)
        local desc="جمع معرفة $topic - تحديث تلقائي"
        local esc_desc
        esc_desc="$(printf '%s' "$desc" | sed "s/'/''/g")"
        val="'$esc_desc'"
        ;;
      payload)
        # JSON بسيط يحتوي على topic + نمط العمل
        local json
        json="$(printf '{"topic":"%s","mode":"multi_source","version":1}' "$topic")"
        local esc_json
        esc_json="$(printf '%s' "$json" | sed "s/'/''/g")"
        val="'$esc_json'"
        ;;
      tags)
        local tags="knowledge,$topic,auto"
        local esc_tags
        esc_tags="$(printf '%s' "$tags" | sed "s/'/''/g")"
        val="'$esc_tags'"
        ;;
      created_at|updated_at)
        val="datetime('now')"
        ;;
      *)
        # أي عمود إضافي غير معرّف نتجاهله
        continue
        ;;
    esac

    if [[ -z "$val" ]]; then
      continue
    fi

    if [[ $first -eq 0 ]]; then
      sql+=", "
    fi
    sql+="$val"
    first=0
  done

  sql+=");"

  log "➕ إدراج مهمة معرفة لمجال: $topic"
  sqlite3 "$DB" "$sql"
}

COUNT=0
for topic in "${TOPICS[@]}"; do
  insert_topic_task "$topic"
  COUNT=$((COUNT + 1))
done

log "✅ تم إدراج $COUNT مهمة معرفة جديدة."

# تقرير سريع بعد الزرع
if sqlite3 "$DB" ".schema tasks" >/dev/null 2>&1; then
  TOTAL_KNOW="$(sqlite3 "$DB" "SELECT COUNT(*) FROM tasks WHERE agent_id='knowledge_spider' AND type='knowledge';")"
  log "📊 إجمالي مهام knowledge_spider / knowledge الآن: $TOTAL_KNOW"
fi

log "✅ انتهى hf_seed_knowledge_tasks بنجاح."
