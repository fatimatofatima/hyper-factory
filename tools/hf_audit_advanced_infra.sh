#!/usr/bin/env bash
set -Eeuo pipefail

# Hyper Factory – Advanced Infra Audit
# يفحص:
# - data_lakehouse/*
# - factories/*
# - agents/*
# - systems المتقدمة (patterns, quality, temporal_memory, integration)

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
ok()   { echo "✅ $*"; }
miss() { echo "❌ $*"; }
part() { echo "⚠️  $*"; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

log "Hyper Factory – Advanced Infrastructure Audit"
log "ROOT_DIR = $ROOT_DIR"
echo

# 1) data_lakehouse
BASE_LH="data_lakehouse"
log "Checking data_lakehouse layout (Raw → Cleansed → Semantic → Serving)..."

need_lh=(
  "$BASE_LH"
  "$BASE_LH/raw"
  "$BASE_LH/cleansed"
  "$BASE_LH/semantic"
  "$BASE_LH/serving"
)

lh_missing=0
for p in "${need_lh[@]}"; do
  if [ -d "$p" ]; then
    ok "Exists: $p"
  else
    lh_missing=$((lh_missing+1))
    miss "Missing: $p"
  fi
done

if [ "$lh_missing" -eq 0 ]; then
  ok "data_lakehouse: COMPLETE"
else
  part "data_lakehouse: INCOMPLETE ($lh_missing missing component(s))"
fi
echo

# 2) factories
log "Checking factories/..."
if [ -d "factories" ]; then
  ok "factories directory exists"
  ls -1 factories || true
else
  miss "factories directory missing"
fi
echo

# 3) agents المتقدمة
log "Checking agents (debug_expert, system_architect, technical_coach, knowledge_spider)..."
AGENTS_EXPECTED=(
  "agents/debug_expert"
  "agents/system_architect"
  "agents/technical_coach"
  "agents/knowledge_spider"
)

agents_missing=0
for a in "${AGENTS_EXPECTED[@]}"; do
  if [ -d "$a" ]; then
    ok "Agent OK: $a"
  else
    agents_missing=$((agents_missing+1))
    miss "Agent missing: $a"
  fi
done

if [ "$agents_missing" -eq 0 ]; then
  ok "All advanced agents present."
else
  part "Some agents missing ($agents_missing)."
fi
echo

# 4) الأنظمة المتقدمة
log "Checking advanced systems (patterns, quality, temporal_memory, integration)..."

SYSTEMS_EXPECTED=(
  "systems/patterns"
  "systems/quality"
  "systems/temporal_memory"
  "systems/integration"
)

systems_missing=0
for s in "${SYSTEMS_EXPECTED[@]}"; do
  if [ -d "$s" ]; then
    ok "System OK: $s"
  else
    systems_missing=$((systems_missing+1))
    miss "System missing: $s"
  fi
done

if [ "$systems_missing" -eq 0 ]; then
  ok "All advanced systems present."
else
  part "Some advanced systems missing ($systems_missing)."
fi
echo

log "Advanced infra audit completed."
