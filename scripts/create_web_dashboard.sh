#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORTS_DIR="$ROOT_DIR/reports"
DASHBOARD_HTML="$REPORTS_DIR/dashboard.html"
ADV_JSON="$REPORTS_DIR/advanced_dashboard.json"

mkdir -p "$REPORTS_DIR"

if [ ! -f "$ADV_JSON" ]; then
  echo "⚠️ لا يوجد advanced_dashboard.json، سيتم توليده الآن..."
  "$ROOT_DIR/scripts/advanced_reporting_system.sh"
fi

python3 << 'PYCODE'
import json
import os
from datetime import datetime
from pathlib import Path

root_dir = Path(__file__).resolve().parents[1]
reports_dir = root_dir / "reports"
adv_json = reports_dir / "advanced_dashboard.json"
out_html = reports_dir / "dashboard.html"

data = {}
if adv_json.exists():
    with open(adv_json, "r", encoding="utf-8") as f:
        data = json.load(f)

html = f"""<!DOCTYPE html>
<html lang="ar">
<head>
  <meta charset="UTF-8">
  <title>Hyper Factory Dashboard</title>
  <style>
    body {{ font-family: sans-serif; direction: rtl; background: #101520; color: #f5f5f5; }}
    h1, h2 {{ color: #4dd0e1; }}
    .card {{ border: 1px solid #333; padding: 1rem; margin: 1rem 0; border-radius: 8px; background:#181d2b; }}
    .meta {{ font-size: 0.85rem; color: #aaa; }}
    ul {{ line-height: 1.7; }}
  </style>
</head>
<body>
  <h1>Hyper Factory - لوحة المتابعة</h1>
  <p class="meta">آخر تحديث: {datetime.now().isoformat()}</p>

  <div class="card">
    <h2>حالة النظام</h2>
    <pre>{json.dumps(data.get("system_health", {}), ensure_ascii=False, indent=2)}</pre>
  </div>

  <div class="card">
    <h2>مؤشرات الأداء</h2>
    <pre>{json.dumps(data.get("performance_metrics", {}), ensure_ascii=False, indent=2)}</pre>
  </div>

  <div class="card">
    <h2>التوصيات</h2>
    <ul>
      {''.join(f'<li>{item}</li>' for item in data.get("recommendations", []))}
    </ul>
  </div>
</body>
</html>
"""

with open(out_html, "w", encoding="utf-8") as f:
    f.write(html)

print(f"✅ تم إنشاء Dashboard HTML في: {out_html}")
PYCODE

