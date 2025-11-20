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
  echo "[HF-AGENTS] DB غير موجود، تشغيل hf_db_core_init.sh أولاً"
  exit 1
fi

echo "[HF-AGENTS] Registering agents from ${CFG} into ${DB_PATH}"

awk '
  # بداية تعريف عامل جديد
  $1=="-" && $2=="id:" {
    id=$3; gsub(/"/,"",id)
    name=""; cat=""; role=""; prio=0; ena="true"; script=""; grp="";
  }
  $1=="display_name:" {
    sub(/display_name:[ ]*/, "", $0)
    name=$0
    gsub(/^"[ ]*/, "", name)
    gsub(/"[ ]*$/, "", name)
    gsub(/\047/, "\047\047", name)  # هروب single quote لو موجود
  }
  $1=="category:" {
    cat=$2; gsub(/"/,"",cat)
  }
  $1=="role:" {
    role=$2; gsub(/"/,"",role)
  }
  $1=="priority:" {
    prio=$2; gsub(/"/,"",prio)
  }
  $1=="enabled:" {
    ena=$2; gsub(/"/,"",ena)
  }
  $1=="script:" {
    sub(/script:[ ]*/, "", $0)
    script=$0
    gsub(/^"[ ]*/, "", script)
    gsub(/"[ ]*$/, "", script)
    gsub(/\047/, "\047\047", script)
  }
  # group هو آخر سطر قبل description → هنا ننفّذ INSERT
  $1=="group:" {
    grp=$2; gsub(/"/,"",grp)
    enabled_val = (ena=="true" ? 1 : 0)
    prio_val = (prio=="" ? 0 : prio+0)

    printf "INSERT OR REPLACE INTO agents (id, display_name, category, role, group_name, priority, enabled, script) VALUES ("
    printf "\047%s\047,", id
    printf "\047%s\047,", name
    printf "\047%s\047,", cat
    printf "\047%s\047,", role
    printf "\047%s\047,", grp
    printf "%d,", prio_val
    printf "%d,", enabled_val
    printf "\047%s\047);\n", script
  }
' "${CFG}" | sqlite3 "${DB_PATH}"

echo "[HF-AGENTS] Done. Current agents in DB:"
sqlite3 "${DB_PATH}" "SELECT id, category, group_name, priority, enabled FROM agents ORDER BY category, priority, id;"
