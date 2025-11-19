#!/usr/bin/env python3
# reporter_basic.py
# عامل تقارير بسيط:
# - يقرأ ملفات semantic من data/semantic
# - يكتب ملخص JSON في data/serving
# - يكتب تقرير نصي في reports/

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
    agent = agents_block.get("reporter_basic", {})

    input_path = agent.get("input", {}).get("path", "./data/semantic")
    output_serving = agent.get("output", {}).get("serving_path", "./data/serving")
    output_reports = agent.get("output", {}).get("reports_path", "./reports")

    input_path = os.path.join(ROOT, os.path.relpath(input_path, "."))
    output_serving = os.path.join(ROOT, os.path.relpath(output_serving, "."))
    output_reports = os.path.join(ROOT, os.path.relpath(output_reports, "."))

    os.makedirs(output_serving, exist_ok=True)
    os.makedirs(output_reports, exist_ok=True)

    print("\n================= 📣 Reporter Basic =================")
    print(f"- INPUT         : {os.path.relpath(input_path, ROOT)}")
    print(f"- SERVING OUT   : {os.path.relpath(output_serving, ROOT)}")
    print(f"- REPORTS OUT   : {os.path.relpath(output_reports, ROOT)}")

    pattern = os.path.join(input_path, "*.semantic.json")
    sem_files = sorted(glob.glob(pattern))

    if not sem_files:
        print("ℹ️ لا توجد ملفات semantic لكتابة تقرير عنها.")
        return

    items = []
    for path in sem_files:
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            items.append({
                "file": data.get("file"),
                "meta_path": data.get("meta_path"),
                "created_at": data.get("created_at"),
            })
        except Exception as e:
            print(f"❌ خطأ في قراءة semantic: {path} ({e})")

    now = datetime.now()
    summary = {
        "generated_at": now.isoformat(timespec="seconds"),
        "semantic_dir": input_path,
        "total_items": len(items),
        "items": items,
        "agent": "reporter_basic",
    }

    serving_path = os.path.join(output_serving, "semantic_serving_summary.json")
    report_txt = os.path.join(output_reports, "semantic_overview.txt")

    try:
        with open(serving_path, "w", encoding="utf-8") as f:
            json.dump(summary, f, ensure_ascii=False, indent=2)
        print(f"✅ تم إنشاء ملف serving: {os.path.relpath(serving_path, ROOT)}")
    except Exception as e:
        print(f"❌ خطأ في كتابة ملف serving: {serving_path} ({e})")

    try:
        lines = []
        lines.append("===== Hyper Factory Semantic Overview =====")
        lines.append(f"Generated at  : {now.strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append(f"Semantic dir  : {os.path.relpath(input_path, ROOT)}")
        lines.append(f"Total items   : {len(items)}")
        lines.append("")
        for item in items:
            lines.append(f"- {item.get('file')} | created_at={item.get('created_at')}")
        content = "\n".join(lines)

        with open(report_txt, "w", encoding="utf-8") as f:
            f.write(content)

        print(f"✅ تم إنشاء تقرير نصي: {os.path.relpath(report_txt, ROOT)}")
    except Exception as e:
        print(f"❌ خطأ في كتابة التقرير النصي: {report_txt} ({e})")

    print("\n✅ انتهى تشغيل reporter_basic.")


if __name__ == "__main__":
    main()
