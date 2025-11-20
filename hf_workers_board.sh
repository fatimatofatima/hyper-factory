#!/usr/bin/env bash
set -e

CFG="config/factory_core.yaml"

if [[ ! -f "$CFG" ]]; then
  echo "config/factory_core.yaml غير موجود"
  exit 1
fi

echo "=== Hyper Factory – Workers Board by Category ==="
echo

awk '
  $1=="-"
  $2=="id:" {
    id=$3; gsub(/"/,"",id)
  }
  $1=="display_name:" {
    # دمج السطر كله كاسم
    sub(/display_name:[ ]*/, "", $0)
    name=$0; gsub(/^"[ ]*/,"",name); gsub(/"[ ]*$/,"",name)
  }
  $1=="category:" {
    cat=$2; gsub(/"/,"",cat)
  }
  $1=="role:" {
    role=$2; gsub(/"/,"",role)
  }
  $1=="enabled:" {
    ena=$2; gsub(/"/,"",ena)
    if (ena == "true") {
      board[cat] = board[cat] sprintf("  - %-16s (%s) [%s]\n", id, name, role)
    } else {
      board[cat] = board[cat] sprintf("  - %-16s (%s) [%s] {disabled}\n", id, name, role)
    }
  }
  END {
    for (c in board) {
      print "Category:", c
      print "----------------------------------"
      printf "%s\n\n", board[c]
    }
  }
' "$CFG"
