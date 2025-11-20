#!/usr/bin/env bash
set -e

CFG="config/factory_core.yaml"

if [[ ! -f "$CFG" ]]; then
  echo "config/factory_core.yaml غير موجود"
  exit 1
fi

echo "ID                | CATEGORY        | GROUP          | PRI | ENABLED"
echo "------------------+----------------+----------------+-----+--------"

awk '
  $1=="-" && $2=="id:" {
    id=$3; gsub(/"/,"",id)
  }
  $1=="category:" {
    cat=$2; gsub(/"/,"",cat)
  }
  $1=="group:" {
    grp=$2; gsub(/"/,"",grp)
  }
  $1=="priority:" {
    prio=$2; gsub(/"/,"",prio)
  }
  $1=="enabled:" {
    ena=$2; gsub(/"/,"",ena)
    printf "%-18s | %-14s | %-14s | %-3s | %-6s\n", id, cat, grp, prio, ena
  }
' "$CFG"
