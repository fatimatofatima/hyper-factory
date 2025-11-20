#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${ROOT_DIR}/config/factory_core.yaml"
DB_DIR="${ROOT_DIR}/data/knowledge"
DB_PATH="${DB_DIR}/knowledge.db"

if [[ ! -f "${CFG}" ]]; then
  echo "[HF-AGENTS] config/factory_core.yaml غير موجود"
  exit 1
fi

if [[ ! -f "${DB_PATH}" ]]; then
  echo "[HF-AGENTS] DB غير موجود: ${DB_PATH}"
  echo "شغّل أولاً: ./hf_db_core_init.sh"
  exit 1
fi

echo "[HF-AGENTS] Registering agents from ${CFG} into ${DB_PATH}"

# نفضّي جدول agents عشان تكون الحالة مرآة لملف YAML الحالي
sqlite3 "${DB_PATH}" "DELETE FROM agents;"

SQL_FILE="${ROOT_DIR}/reports/diagnostics/hf_agents_sync.sql"
mkdir -p "$(dirname "${SQL_FILE}")"

awk '
  BEGIN {
    id = ""
    display_name = ""
    category = ""
    group_name = ""
    role = ""
    priority = 0
    enabled = "true"
    script = ""
  }

  # بداية تعريف عامل جديد
  $1=="-" && $2=="id:" {
    # لو في عامل سابق، نطلّع له INSERT
    if (id != "") {
      enabled_val = (enabled == "true" || enabled == "True" || enabled == "1") ? 1 : 0

      # escaping للأبستروف داخل النصوص
      gsub(/\047/, "\047\047", display_name)
      gsub(/\047/, "\047\047", category)
      gsub(/\047/, "\047\047", group_name)
      gsub(/\047/, "\047\047", role)
      gsub(/\047/, "\047\047", script)

      printf "INSERT OR REPLACE INTO agents (id, display_name, category, group_name, role, priority, enabled, script) VALUES ("
      printf "'%s','%s','%s','%s','%s',%d,%d,'%s');\n", id, display_name, category, group_name, role, priority, enabled_val, script
    }

    # نجهز تعريف العامل الجديد
    id = $3
    gsub(/"/, "", id)
    display_name = ""
    category = ""
    group_name = ""
    role = ""
    priority = 0
    enabled = "true"
    script = ""

    next
  }

  $1=="display_name:" {
    sub(/display_name:[ ]*/, "", $0)
    display_name = $0
    sub(/^"[ ]*/, "", display_name)
    sub(/"[ ]*$/, "", display_name)
    next
  }

  $1=="category:" {
    category = $2
    gsub(/"/, "", category)
    next
  }

  $1=="group:" {
    group_name = $2
    gsub(/"/, "", group_name)
    next
  }

  $1=="role:" {
    role = $2
    gsub(/"/, "", role)
    next
  }

  $1=="priority:" {
    priority = $2
    next
  }

  $1=="enabled:" {
    enabled = $2
    gsub(/,/, "", enabled)
    next
  }

  $1=="script:" {
    sub(/script:[ ]*/, "", $0)
    script = $0
    sub(/^"[ ]*/, "", script)
    sub(/"[ ]*$/, "", script)
    next
  }

  END {
    # آخر عامل في الملف
    if (id != "") {
      enabled_val = (enabled == "true" || enabled == "True" || enabled == "1") ? 1 : 0

      gsub(/\047/, "\047\047", display_name)
      gsub(/\047/, "\047\047", category)
      gsub(/\047/, "\047\047", group_name)
      gsub(/\047/, "\047\047", role)
      gsub(/\047/, "\047\047", script)

      printf "INSERT OR REPLACE INTO agents (id, display_name, category, group_name, role, priority, enabled, script) VALUES ("
      printf "'%s','%s','%s','%s','%s',%d,%d,'%s');\n", id, display_name, category, group_name, role, priority, enabled_val, script
    }
  }
' "${CFG}" > "${SQL_FILE}"

echo "[HF-AGENTS] Generated SQL: ${SQL_FILE}"
sqlite3 "${DB_PATH}" < "${SQL_FILE}"
echo "[HF-AGENTS] Done. Agents synchronized with YAML."
