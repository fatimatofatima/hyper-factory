#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
hf_roles_engine.py

محرك الأدوار ومستويات الـ Agents لـ Hyper Factory.

المصادر:
  - config/roles.json
  - data/report/summary_basic.json

النواتج:
  - ai/memory/people/agents_levels.json   (قابل للاستهلاك من Manager Dashboard + Knowledge Spider)
  - ai/memory/people/agents_levels.txt    (ملخص نصي للقراءة السريعة)
"""

import json
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent

ROLES_CONFIG_PATH = ROOT / "config" / "roles.json"
SUMMARY_BASIC_PATH = ROOT / "data" / "report" / "summary_basic.json"
PEOPLE_DIR = ROOT / "ai" / "memory" / "people"
AGENTS_LEVELS_JSON = PEOPLE_DIR / "agents_levels.json"
AGENTS_LEVELS_TXT = PEOPLE_DIR / "agents_levels.txt"


def load_json(path, default=None):
    if default is None:
        default = {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"⚠️ لم يتم العثور على الملف: {path}")
    except Exception as e:
        print(f"⚠️ خطأ أثناء قراءة JSON من {path}: {e}")
    return default


def pick_level(success_rate, levels_cfg):
    """
    اختيار المستوى الأنسب بناءً على success_rate
    يستخدم thresholds من config/roles.json["levels"].
    """
    if not levels_cfg:
        return "junior"

    # نبني قائمة (level_name, min_success_rate, multiplier)
    entries = []
    for name, cfg in levels_cfg.items():
        min_sr = float(cfg.get("min_success_rate", 0.0))
        entries.append((name, min_sr))

    # ترتيب حسب min_success_rate تصاعديًا
    entries.sort(key=lambda x: x[1])

    chosen = entries[0][0]
    for name, min_sr in entries:
        if success_rate >= min_sr:
            chosen = name
    return chosen


def main():
    print("📂 ROOT            :", ROOT)
    print("📄 roles.json      :", ROLES_CONFIG_PATH)
    print("📄 summary_basic   :", SUMMARY_BASIC_PATH)
    print("📄 agents_levels   :", AGENTS_LEVELS_JSON)
    print("--------------------------------------------------")

    roles_cfg = load_json(ROLES_CONFIG_PATH, {})
    summary = load_json(SUMMARY_BASIC_PATH, {})

    levels_cfg = roles_cfg.get("levels", {})
    roles_map = roles_cfg.get("roles", {})
    agents_map = roles_cfg.get("agents", {})

    if not agents_map:
        print("⚠️ لا توجد agents معرفة في config/roles.json → القسم 'agents'. لن يتم توليد شيء.")
        return

    total_runs = int(summary.get("total_runs") or 0)
    success_runs = int(summary.get("success_runs") or 0)
    failed_runs = int(summary.get("failed_runs") or 0)

    if total_runs > 0:
        success_rate = success_runs / total_runs
    else:
        success_rate = 0.0

    print(f"📊 إجمالي الدورات   : {total_runs}")
    print(f"✅ الناجحة           : {success_runs}")
    print(f"❌ الفاشلة           : {failed_runs}")
    print(f"📈 نسبة النجاح      : {success_rate:.2%}")
    print("--------------------------------------------------")

    PEOPLE_DIR.mkdir(parents=True, exist_ok=True)

    agents_levels = []
    lines_txt = []
    lines_txt.append(f"# Agents Levels generated at {datetime.utcnow().isoformat()}Z")
    lines_txt.append("# agent_id | display_name | family | level | success_rate | salary_index | total_runs | success_runs | failed_runs")
    lines_txt.append("")

    for agent_name, agent_meta in agents_map.items():
        role_key = agent_meta.get("role")
        role_cfg = roles_map.get(role_key, {})

        family = role_cfg.get("family", "pipeline")
        display_name = role_cfg.get("title", agent_name)

        level_name = pick_level(success_rate, levels_cfg)
        level_cfg = levels_cfg.get(level_name, {})
        multiplier = float(level_cfg.get("multiplier", 1.0))
        base_salary = float(role_cfg.get("base_salary_index", 1.0))
        salary_index = round(base_salary * multiplier, 2)

        item = {
            "agent": agent_name,
            "family": family,
            "role": role_key,
            "display_name": display_name,
            "level": level_name,
            "salary_index": salary_index,
            "success_rate": round(success_rate, 4),
            "total_runs": total_runs,
            "success_runs": success_runs,
            "failed_runs": failed_runs,
        }
        agents_levels.append(item)

        lines_txt.append(
            f"{agent_name} | {display_name} | {family} | {level_name} | "
            f"{success_rate:.2%} | {salary_index} | {total_runs} | {success_runs} | {failed_runs}"
        )

    # حفظ JSON
    try:
        with open(AGENTS_LEVELS_JSON, "w", encoding="utf-8") as f:
            json.dump(agents_levels, f, ensure_ascii=False, indent=2)
        print(f"✅ تم حفظ agents_levels.json إلى: {AGENTS_LEVELS_JSON}")
    except Exception as e:
        print(f"⚠️ فشل حفظ agents_levels.json: {e}")

    # حفظ TXT
    try:
        with open(AGENTS_LEVELS_TXT, "w", encoding="utf-8") as f:
            f.write("\n".join(lines_txt) + "\n")
        print(f"✅ تم حفظ agents_levels.txt إلى: {AGENTS_LEVELS_TXT}")
    except Exception as e:
        print(f"⚠️ فشل حفظ agents_levels.txt: {e}")


if __name__ == "__main__":
    main()
