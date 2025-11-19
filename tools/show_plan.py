#!/usr/bin/env python3
"""
tools/show_plan.py
عرض خطة Hyper Factory من:
- config/factory.yaml
- config/agents.yaml

لا ينفّذ أي عامل، فقط يطبع الخريطة الحالية.
"""

import os
import sys
from textwrap import indent

try:
    import yaml
except ImportError:
    print("❌ مكتبة PyYAML غير مثبتة.")
    print("   استخدم: pip3 install pyyaml")
    sys.exit(1)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_DIR = os.path.join(ROOT, "config")
FACTORY_PATH = os.path.join(CONFIG_DIR, "factory.yaml")
AGENTS_PATH = os.path.join(CONFIG_DIR, "agents.yaml")


def load_yaml(path, label):
    if not os.path.exists(path):
        print(f"❌ {label} غير موجود: {path}")
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        print(f"✅ تم تحميل {label}: {path}")
        return data
    except Exception as e:
        print(f"❌ خطأ في قراءة {label} ({path}): {e}")
        return None


def print_factory(factory_cfg):
    print("\n===== 🏭 Factory =====")
    factory = (factory_cfg or {}).get("factory", {}) or {}
    paths = (factory_cfg or {}).get("paths", {}) or {}

    name = factory.get("name", "Hyper Factory")
    desc = factory.get("description", "").strip()
    version = factory.get("version", "")

    print(f"اسم المصنع   : {name}")
    if version:
        print(f"الإصدار      : {version}")
    if desc:
        print(f"الوصف        : {desc}")

    print("\n[Paths]")
    keys = [
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
    ]
    for k in keys:
        v = paths.get(k)
        if v:
            print(f"- {k:<15}: {v}")


def print_agents(agents_cfg):
    print("\n===== 🤖 Agents =====")
    agents_root = (agents_cfg or {}).get("agents", {}) or {}
    if not isinstance(agents_root, dict) or not agents_root:
        print("ℹ️ لا يوجد agents معرّفين في agents.yaml.")
        return

    for name, spec in agents_root.items():
        if not isinstance(spec, dict):
            continue
        role = spec.get("role", "")
        desc = spec.get("description", "")
        enabled = spec.get("enabled", True)

        print(f"\n--- {name} ---")
        print(f"role      : {role}")
        print(f"enabled   : {enabled}")
        if desc:
            print(f"description:")
            print(indent(desc, "  "))

        inp = spec.get("input", {})
        out = spec.get("output", {})

        print("input:")
        if isinstance(inp, dict) and inp:
            for k, v in inp.items():
                print(f"  - {k}: {v}")
        else:
            print("  (لا شيء)")

        print("output:")
        if isinstance(out, dict) and out:
            for k, v in out.items():
                print(f"  - {k}: {v}")
        else:
            print("  (لا شيء)")


def print_orchestrator(agents_cfg):
    orch = (agents_cfg or {}).get("orchestrator", {}) or {}
    print("\n===== 🎛 Orchestrator =====")
    if not orch:
        print("ℹ️ لا يوجد بلوك orchestrator في agents.yaml.")
        return

    enabled = orch.get("enabled", False)
    strategy = orch.get("strategy", "sequential")
    desc = orch.get("description", "")
    notes = orch.get("notes", "")

    print(f"enabled   : {enabled}")
    print(f"strategy  : {strategy}")
    if desc:
        print(f"description:")
        print(indent(desc, "  "))
    if notes:
        print(f"notes:")
        print(indent(notes, "  "))


def main():
    print(f"📁 ROOT       : {ROOT}")
    print(f"📂 CONFIG_DIR : {CONFIG_DIR}")
    print("----------------------------------------")

    factory_cfg = load_yaml(FACTORY_PATH, "factory.yaml")
    agents_cfg = load_yaml(AGENTS_PATH, "agents.yaml")

    if not factory_cfg and not agents_cfg:
        print("⚠️ لا توجد إعدادات كافية لعرض الخطة.")
        sys.exit(1)

    print_factory(factory_cfg or {})
    print_agents(agents_cfg or {})
    print_orchestrator(agents_cfg or {})

    print("\n✅ انتهى عرض خطة Hyper Factory (قراءة فقط).")


if __name__ == "__main__":
    main()
