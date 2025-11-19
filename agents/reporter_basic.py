#!/usr/bin/env python3
# reporter_basic.py
# عامل تقارير بسيط:
# - يقرأ data/semantic/semantic_index.jsonl
# - ينتج:
#   - data/serving/semantic_summary.json
#   - reports/semantic_report.txt

import os
import sys
import json
from pathlib import Path
from datetime import datetime

try:
    import yaml
except ImportError:
    print("❌ مكتبة PyYAML غير مثبتة.")
    print("   استخدم: pip3 install pyyaml")
    sys.exit(1)

ROOT = Path(__file__).resolve().parents[1]
CONFIG_DIR = ROOT / "config"
AGENTS_PATH = CONFIG_DIR / "agents.yaml"


def load_agents():
    if not AGENTS_PATH.exists():
        print(f"❌ ملف agents.yaml غير موجود: {AGENTS_PATH}")
        sys.exit(1)
    with AGENTS_PATH.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def resolve_path_from_cfg(cfg, key, default):
    if cfg is None:
        return default

    if isinstance(cfg, dict):
        return cfg.get(key, default)

    if isinstance(cfg, list):
        for item in cfg:
            if isinstance(item, dict) and key in item:
                return item[key]
        return default

    return default


def main():
    print("📁 ROOT       :", ROOT)
    print("📂 CONFIG_DIR :", CONFIG_DIR)
    print("----------------------------------------")

    agents_cfg = load_agents()
    agents_block = agents_cfg.get("agents", {})
    reporter_cfg = agents_block.get("reporter_basic")

    if not reporter_cfg:
        print("❌ لم يتم العثور على تكوين reporter_basic في agents.yaml")
        sys.exit(1)

    input_cfg = reporter_cfg.get("input")
    output_cfg = reporter_cfg.get("output")

    input_path_str = resolve_path_from_cfg(input_cfg, "path", "./data/semantic")
    serving_path_str = resolve_path_from_cfg(output_cfg, "serving_path", "./data/serving")
    reports_path_str = resolve_path_from_cfg(output_cfg, "reports_path", "./reports")

    input_dir = (ROOT / input_path_str).resolve()
    serving_dir = (ROOT / serving_path_str).resolve()
    reports_dir = (ROOT / reports_path_str).resolve()

    print("================= 📑 Reporter Basic =================")
    print(f"- INPUT   : {input_dir}")
    print(f"- SERVING : {serving_dir}")
    print(f"- REPORTS : {reports_dir}")

    index_path = input_dir / "semantic_index.jsonl"

    if not index_path.exists():
        print(f"ℹ️ ملف semantic_index.jsonl غير موجود بعد: {index_path}")
        print("ℹ️ شغّل analyzer_basic أولاً لتهيئة البيانات.")
        serving_dir.mkdir(parents=True, exist_ok=True)
        reports_dir.mkdir(parents=True, exist_ok=True)
        # نكتب تقارير فارغة
        (serving_dir / "semantic_summary.json").write_text(
            json.dumps(
                {
                    "generated_at": datetime.utcnow().isoformat() + "Z",
                    "records": 0,
                    "note": "no semantic_index.jsonl yet",
                },
                ensure_ascii=False,
                indent=2,
            ),
            encoding="utf-8",
        )
        (reports_dir / "semantic_report.txt").write_text(
            "No semantic_index.jsonl exists yet.\n",
            encoding="utf-8",
        )
        sys.exit(0)

    serving_dir.mkdir(parents=True, exist_ok=True)
    reports_dir.mkdir(parents=True, exist_ok=True)

    records = []
    per_type = {}

    with index_path.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            records.append(rec)
            fields = rec.get("fields", {})
            rec_type = fields.get("type") or fields.get("category") or "unknown"
            per_type[rec_type] = per_type.get(rec_type, 0) + 1

    total = len(records)
    last_id = records[-1].get("id") if records else None

    summary = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "index_path": str(index_path),
        "total_records": total,
        "per_type": per_type,
        "last_record_id": last_id,
    }

    summary_json_path = serving_dir / "semantic_summary.json"
    summary_txt_path = reports_dir / "semantic_report.txt"

    summary_json_path.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    lines = []
    lines.append("===== Hyper Factory Semantic Report =====")
    lines.append(f"Generated at   : {summary['generated_at']}")
    lines.append(f"Index file     : {summary['index_path']}")
    lines.append("")
    lines.append(f"Total records  : {total}")
    lines.append("")
    lines.append("Per type breakdown:")
    if per_type:
        for t, c in per_type.items():
            lines.append(f"  - {t}: {c}")
    else:
        lines.append("  (no type information available)")
    lines.append("")
    lines.append(f"Last record id : {last_id}")
    lines.append("")

    summary_txt_path.write_text("\n".join(lines), encoding="utf-8")

    print("----------------- 📊 ملخص Reporter -----------------")
    print(f"- عدد السجلات       : {total}")
    print(f"- ملف JSON (serving): {summary_json_path}")
    print(f"- ملف TXT (report)  : {summary_txt_path}")
    print("✅ انتهى تشغيل reporter_basic.")
    sys.exit(0)


if __name__ == "__main__":
    main()
