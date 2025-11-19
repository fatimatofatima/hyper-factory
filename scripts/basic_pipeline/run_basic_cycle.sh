#!/usr/bin/env bash
# scripts/basic_pipeline/run_basic_cycle.sh
# رابر بسيط لدورة Hyper Factory الأساسية الموجودة في جذر المشروع.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "📂 SCRIPT_DIR : $SCRIPT_DIR"
echo "📂 ROOT       : $ROOT"
echo "----------------------------------------"

bash "$ROOT/run_basic_cycle.sh"
