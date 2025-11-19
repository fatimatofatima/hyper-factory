#!/usr/bin/env python3
# analyzer_basic.py
# عامل تحليل بسيط:
# - يقرأ ملفات meta من data/processed
# - يحوّلها إلى JSON في data/semantic

import os
import sys
import glob
import json
from datetime import datetime

try:
    import yaml
except ImportError:
    print("❌ مكتبة PyYAML غير مثبتة. نفّذ: pip3 install pyyaml")
    sys.exit(1)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_DIR = os.path.join(ROOT, "config")
FACTORY_PATH = os.path.join(CONFIG_DIR, "factory.yaml")
AGENTS_PATH = os.path.join(CONFIG_DIR, "agents.yaml")


def load_yaml(path, label):
    if not os.path.exists(path):
        print(f"❌ ملف {label} غير موجود: {path}")
        sys.exit(1)
    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
    print(f"✅ تم تحميل {label}: {path}")
    return data


def main():
    print("📁 ROOT       :", ROOT)
    print("📂 CONFIG_DIR :", CONFIG_DIR)
    print("----------------------------------------")

    factory_cfg = load_yaml(FACTORY_PATH, "factory.yaml")
    agents_cfg = load_yaml(AGENTS_PATH, "agents.yaml")

    agents_block = agents_cfg.get("agents", agents_cfg)
    agent = agents_block.get("analyzer_basic", {})

    input_path = agent.get("input", {}).get("path", "./data/processed")
    output_path = agent.get("output", {}).get("path", "./data/semantic")

    input_path = os.path.join(ROOT, os.path.relpath(input_path, "."))
    output_path = os.path.join(ROOT, os.path.relpath(output_path, "."))

    os.makedirs(output_path, exist_ok=True)

    print("\n================= 🔍 Analyzer Basic =================")
    print(f"- INPUT   : {os.path.relpath(input_path, ROOT)}")
    print(f"- OUTPUT  : {os.path.relpath(output_path, ROOT)}")

    pattern = os.path.join(input_path, "*.meta.txt")
    meta_files = sorted(glob.glob(pattern))

    if not meta_files:
        print("ℹ️ لا توجد ملفات meta لمعالجتها.")
        return

    total = 0
    created = 0
    skipped = 0

    for meta_path in meta_files:
        total += 1
        base = os.path.basename(meta_path)
        stem = base.replace(".meta.txt", "")
        out_path = os.path.join(output_path, f"{stem}.semantic.json")

        if os.path.exists(out_path):
            print(f"↩️ SKIP (semantic موجود مسبقاً): {os.path.basename(out_path)}")
            skipped += 1
            continue

        try:
            with open(meta_path, "r", encoding="utf-8") as f:
                meta_text = f.read().strip()
        except Exception as e:
            print(f"❌ خطأ في قراءة meta: {meta_path} ({e})")
            skipped += 1
            continue

        record = {
            "file": stem,
            "meta_path": meta_path,
            "meta_text": meta_text,
            "agent": "analyzer_basic",
            "created_at": datetime.now().isoformat(timespec="seconds"),
        }

        try:
            with open(out_path, "w", encoding="utf-8") as f:
                json.dump(record, f, ensure_ascii=False, indent=2)
            print(f"✅ SEMANTIC: {os.path.basename(out_path)}")
            created += 1
        except Exception as e:
            print(f"❌ خطأ في كتابة semantic: {out_path} ({e})")
            skipped += 1

    print("\n================= 📊 ملخص Analyzer =================")
    print(f"- العدد الكلي        : {total}")
    print(f"- تم إنشاء semantic : {created}")
    print(f"- تم تخطيه           : {skipped}")
    print(f"- الوقت              : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("\n✅ انتهى تشغيل analyzer_basic.")


if __name__ == "__main__":
    main()
