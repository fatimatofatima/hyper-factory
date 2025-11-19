#!/usr/bin/env python3
# processor_basic.py - عامل معالجة بسيط:
# - يقرأ factory.yaml + agents.yaml
# - يحدد مسارات input (processed) و output (semantic)
# - ينشئ ملف meta بسيط لكل ملف (حجم، عدد سطور، تاريخ)

import os
import sys
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
AGENT_NAME = "processor_basic"


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
    factory_processed = paths.get("processed_dir") or os.path.join(ROOT, "data", "processed")
    factory_semantic = paths.get("semantic_dir") or os.path.join(ROOT, "data", "semantic")

    # إعدادات agent من agents.yaml
    agents = (agents_cfg or {}).get("agents", {})
    spec = agents.get(AGENT_NAME, {}) if isinstance(agents, dict) else {}

    input_cfg = spec.get("input", {}) if isinstance(spec, dict) else {}
    output_cfg = spec.get("output", {}) if isinstance(spec, dict) else {}

    input_dir = input_cfg.get("path") or factory_processed
    output_dir = output_cfg.get("path") or factory_semantic

    return input_dir, output_dir, spec


def analyze_file(path):
    """تحليل بسيط: حجم الملف + عدد السطور"""
    try:
        size_bytes = os.path.getsize(path)
    except OSError:
        size_bytes = -1

    line_count = 0
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            for _ in f:
                line_count += 1
    except Exception:
        line_count = -1

    return size_bytes, line_count


def run_processor(input_dir, output_dir):
    print("\n================= 🧠 Processor Basic =================")
    print(f"- INPUT   : {input_dir}")
    print(f"- OUTPUT  : {output_dir}")

    if not os.path.exists(input_dir):
        print(f"ℹ️ مسار INPUT غير موجود: {input_dir}")
        return

    os.makedirs(output_dir, exist_ok=True)

    entries = sorted(os.listdir(input_dir))
    files = [f for f in entries if os.path.isfile(os.path.join(input_dir, f))]

    if not files:
        print("ℹ️ لا توجد ملفات في INPUT حالياً.")
        return

    total = len(files)
    processed = 0
    skipped = 0

    for name in files:
        src = os.path.join(input_dir, name)
        meta_name = f"{name}.meta.txt"
        dst = os.path.join(output_dir, meta_name)

        if os.path.exists(dst):
            print(f"↩️ SKIP (meta موجودة مسبقاً): {meta_name}")
            skipped += 1
            continue

        size_bytes, line_count = analyze_file(src)

        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        try:
            with open(dst, "w", encoding="utf-8") as f:
                f.write(f"file_name: {name}\n")
                f.write(f"path: {src}\n")
                f.write(f"size_bytes: {size_bytes}\n")
                f.write(f"line_count: {line_count}\n")
                f.write(f"processed_at: {now}\n")
            print(f"✅ META: {meta_name}")
            processed += 1
        except Exception as e:
            print(f"❌ فشل إنشاء meta لـ {name}: {e}")

    print("\n================= 📊 ملخص Processor =================")
    print(f"- العدد الكلي      : {total}")
    print(f"- تم إنشاء meta    : {processed}")
    print(f"- تم تخطيه         : {skipped}")
    print(f"- الوقت            : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")


def main():
    print(f"📁 ROOT       : {ROOT}")
    print(f"📂 CONFIG_DIR : {CONFIG_DIR}")
    print(f"🤖 AGENT      : {AGENT_NAME}")

    factory_path = os.path.join(CONFIG_DIR, "factory.yaml")
    agents_path = os.path.join(CONFIG_DIR, "agents.yaml")

    factory_cfg = load_yaml(factory_path, "factory.yaml")
    agents_cfg = load_yaml(agents_path, "agents.yaml")

    input_dir, output_dir, spec = resolve_paths(factory_cfg, agents_cfg)

    enabled = spec.get("enabled", True)
    if not enabled:
        print(f"⚠️ العامل {AGENT_NAME} غير مفعّل (enabled=false في agents.yaml). سيتم الإنهاء.")
        sys.exit(0)

    run_processor(input_dir, output_dir)

    print("\n✅ انتهى تشغيل processor_basic.")


if __name__ == "__main__":
    main()
