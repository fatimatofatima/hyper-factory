#!/usr/bin/env python3
# analyzer_basic.py
# عامل تحليل بسيط:
# - يقرأ ملفات meta من data/processed
# - يبني تمثيل دلالي مبسّط في data/semantic/semantic_index.jsonl

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
    """
    يدعم الشكلين:
    input:
      path: ...
    أو:
    input:
      - path: ...
    """
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


def parse_meta_file(path: Path):
    data = {}
    try:
        with path.open("r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if ":" in line:
                    k, v = line.split(":", 1)
                    data[k.strip()] = v.strip()
    except Exception as e:
        print(f"⚠️ تعذّر قراءة meta: {path} -> {e}")

    if not data:
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            text = ""
        data = {"raw_text": text}

    return data


def main():
    print("📁 ROOT       :", ROOT)
    print("📂 CONFIG_DIR :", CONFIG_DIR)
    print("----------------------------------------")

    agents_cfg = load_agents()
    agents_block = agents_cfg.get("agents", {})
    analyzer_cfg = agents_block.get("analyzer_basic")

    if not analyzer_cfg:
        print("❌ لم يتم العثور على تكوين analyzer_basic في agents.yaml")
        sys.exit(1)

    input_cfg = analyzer_cfg.get("input")
    output_cfg = analyzer_cfg.get("output")

    input_path_str = resolve_path_from_cfg(input_cfg, "path", "./data/processed")
    output_path_str = resolve_path_from_cfg(output_cfg, "path", "./data/semantic")

    input_dir = (ROOT / input_path_str).resolve()
    output_dir = (ROOT / output_path_str).resolve()

    print("================= 🧩 Analyzer Basic =================")
    print(f"- INPUT   : {input_dir}")
    print(f"- OUTPUT  : {output_dir}")

    if not input_dir.exists():
        print(f"⚠️ مجلد الإدخال غير موجود: {input_dir}")
        sys.exit(0)

    output_dir.mkdir(parents=True, exist_ok=True)

    index_path = output_dir / "semantic_index.jsonl"

    meta_files = sorted(input_dir.glob("*.meta.txt"))
    if not meta_files:
        print("ℹ️ لا توجد ملفات *.meta.txt في مجلد الإدخال.")
        # نكتب ملف فارغ (لضمان وجوده)
        index_path.write_text("", encoding="utf-8")
        sys.exit(0)

    records = 0
    with index_path.open("w", encoding="utf-8") as out_f:
        for meta_file in meta_files:
            meta_data = parse_meta_file(meta_file)
            record = {
                "id": meta_file.stem.replace(".meta", ""),
                "meta_path": str(meta_file),
                "created_at": datetime.utcnow().isoformat() + "Z",
                "fields": meta_data,
            }
            out_f.write(json.dumps(record, ensure_ascii=False) + "\n")
            records += 1

    print("----------------- 📊 ملخص Analyzer -----------------")
    print(f"- عدد ملفات meta المعالجة : {records}")
    print(f"- ملف الفهرس              : {index_path}")
    print("✅ انتهى تشغيل analyzer_basic.")
    sys.exit(0)


if __name__ == "__main__":
    main()
