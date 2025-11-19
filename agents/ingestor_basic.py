#!/usr/bin/env python3
# ingestor_basic.py - عامل إدخال بسيط:
# - يقرأ factory.yaml + agents.yaml
# - يحدد مسارات raw / processed
# - ينسخ الملفات من raw إلى processed مع تقرير

import os
import sys
import shutil
from datetime import datetime

try:
    import yaml
except ImportError:
    print("❌ مكتبة PyYAML غير مثبتة.")
    print("   ثبّت المكتبة بالأمر:")
    print("   pip3 install pyyaml")
    sys.exit(1)


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_DIR = os.path.join(ROOT, "config")
AGENT_NAME = "ingestor_basic"


def load_yaml(path, label):
    if not os.path.exists(path):
        print(f"❌ الملف {label} غير موجود: {path}")
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        print(f"✅ تم تحميل {label}: {path}")
        return data
    except Exception as e:
        print(f"❌ خطأ أثناء قراءة {label} ({path}): {e}")
        return None


def resolve_paths(factory_cfg, agents_cfg):
    # مسارات عامة من factory.yaml
    paths = (factory_cfg or {}).get("paths", {})
    factory_raw = paths.get("raw_dir") or os.path.join(ROOT, "data", "raw")
    factory_processed = paths.get("processed_dir") or os.path.join(ROOT, "data", "processed")

    # إعدادات agent من agents.yaml
    agents = (agents_cfg or {}).get("agents", {})
    spec = agents.get(AGENT_NAME, {}) if isinstance(agents, dict) else {}

    input_cfg = spec.get("input", {}) if isinstance(spec, dict) else {}
    output_cfg = spec.get("output", {}) if isinstance(spec, dict) else {}

    raw_dir = input_cfg.get("path") or factory_raw
    processed_dir = output_cfg.get("path") or factory_processed

    return raw_dir, processed_dir, spec


def run_ingestor(raw_dir, processed_dir):
    print("\n================= 🚚 Ingestor Basic =================")
    print(f"- RAW       : {raw_dir}")
    print(f"- PROCESSED : {processed_dir}")

    if not os.path.exists(raw_dir):
        print(f"ℹ️ مسار RAW غير موجود، سيتم إنشاؤه: {raw_dir}")
        os.makedirs(raw_dir, exist_ok=True)

    os.makedirs(processed_dir, exist_ok=True)

    entries = sorted(os.listdir(raw_dir))
    files = [f for f in entries if os.path.isfile(os.path.join(raw_dir, f))]

    if not files:
        print("ℹ️ لا توجد ملفات في RAW حالياً.")
        return

    total = len(files)
    copied = 0
    skipped = 0

    for name in files:
        src = os.path.join(raw_dir, name)
        dst = os.path.join(processed_dir, name)

        if os.path.exists(dst):
            print(f"↩️ SKIP (موجود مسبقاً): {name}")
            skipped += 1
            continue

        try:
            shutil.copy2(src, dst)
            print(f"✅ COPY: {name}")
            copied += 1
        except Exception as e:
            print(f"❌ فشل نسخ {name}: {e}")

    print("\n================= 📊 ملخص Ingestor =================")
    print(f"- العدد الكلي  : {total}")
    print(f"- تم نسخه      : {copied}")
    print(f"- تم تخطيه     : {skipped}")
    print(f"- الوقت        : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")


def main():
    print(f"📁 ROOT       : {ROOT}")
    print(f"📂 CONFIG_DIR : {CONFIG_DIR}")
    print(f"🤖 AGENT      : {AGENT_NAME}")

    factory_path = os.path.join(CONFIG_DIR, "factory.yaml")
    agents_path = os.path.join(CONFIG_DIR, "agents.yaml")

    factory_cfg = load_yaml(factory_path, "factory.yaml")
    agents_cfg = load_yaml(agents_path, "agents.yaml")

    raw_dir, processed_dir, spec = resolve_paths(factory_cfg, agents_cfg)

    enabled = spec.get("enabled", True)
    if not enabled:
        print(f"⚠️ العامل {AGENT_NAME} غير مفعّل (enabled=false في agents.yaml). سيتم الإنهاء.")
        sys.exit(0)

    run_ingestor(raw_dir, processed_dir)

    print("\n✅ انتهى تشغيل ingestor_basic.")


if __name__ == "__main__":
    main()
