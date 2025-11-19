#!/usr/bin/env python3
# hf_show_plan.py - قراءة factory.yaml + agents.yaml وعرض خطة العمل (بدون تنفيذ)

import os
import sys

try:
    import yaml
except ImportError:
    print("❌ مكتبة PyYAML غير مثبتة.")
    print("   ثبّت المكتبة أولاً بالأمر التالي ثم أعد التشغيل:\n")
    print("   pip3 install pyyaml")
    sys.exit(1)


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_DIR = os.path.join(ROOT, "config")


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


def print_factory_info(factory_cfg):
    print("\n================= 🏭 معلومات المصنع =================")
    factory = factory_cfg.get("factory", {})
    paths = factory_cfg.get("paths", {})
    data_policies = factory_cfg.get("data_policies", {})
    logging_cfg = factory_cfg.get("logging", {})

    print(f"- الاسم        : {factory.get('name', 'N/A')}")
    print(f"- الوصف       : {factory.get('description', 'N/A')}")
    print(f"- الإصدار     : {factory.get('version', 'N/A')}")

    print("\n📂 المسارات الأساسية:")
    for key in [
        "root",
        "data_home",
        "raw_dir",
        "processed_dir",
        "semantic_dir",
        "serving_dir",
        "agents_root",
        "pipelines_root",
        "models_root",
        "experiments_root",
        "logs_dir",
        "reports_dir",
        "audit_dir",
    ]:
        if key in paths:
            print(f"  - {key:15}: {paths[key]}")

    print("\n📜 سياسات البيانات:")
    for k, v in data_policies.items():
        print(f"  - {k}: {v}")

    print("\n🧾 إعدادات الـ logging:")
    for k, v in logging_cfg.items():
        print(f"  - {k}: {v}")


def print_agents_info(agents_cfg):
    print("\n================= 🤖 تعريف العمال =================")
    agents = agents_cfg.get("agents", {})
    if not agents:
        print("ℹ️ لا يوجد أي agents معرّفين في agents.yaml.")
        return

    for name, spec in agents.items():
        role = spec.get("role", "N/A")
        desc = spec.get("description", "")
        enabled = spec.get("enabled", False)
        input_cfg = spec.get("input", {})
        output_cfg = spec.get("output", {})

        print(f"\n--- عامل: {name} ---")
        print(f"- الدور        : {role}")
        print(f"- مفعّل؟      : {enabled}")
        print(f"- الوصف       : {desc}")

        # Input
        print("  📥 Input:")
        if isinstance(input_cfg, dict):
            for k, v in input_cfg.items():
                print(f"    - {k}: {v}")
        else:
            print(f"    {input_cfg}")

        # Output
        print("  📤 Output:")
        if isinstance(output_cfg, dict):
            for k, v in output_cfg.items():
                print(f"    - {k}: {v}")
        else:
            print(f"    {output_cfg}")

    orchestrator_cfg = agents_cfg.get("orchestrator", {})
    if orchestrator_cfg:
        print("\n================= 🧠 Orchestrator =================")
        for k, v in orchestrator_cfg.items():
            print(f"- {k}: {v}")


def main():
    print(f"📁 ROOT       : {ROOT}")
    print(f"📂 CONFIG_DIR : {CONFIG_DIR}")

    factory_path = os.path.join(CONFIG_DIR, "factory.yaml")
    agents_path = os.path.join(CONFIG_DIR, "agents.yaml")

    factory_cfg = load_yaml(factory_path, "factory.yaml")
    agents_cfg = load_yaml(agents_path, "agents.yaml")

    if not factory_cfg and not agents_cfg:
        print("\n❌ لا يمكن إكمال الخطة: لا يوجد أي من ملفات الإعداد.")
        sys.exit(1)

    if factory_cfg:
        print_factory_info(factory_cfg)

    if agents_cfg:
        print_agents_info(agents_cfg)

    print("\n✅ انتهى عرض خطة المصنع (لا يوجد أي تنفيذ حقيقي حتى الآن).")


if __name__ == "__main__":
    main()
