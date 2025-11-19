#!/usr/bin/env python3
"""
tools/hf_roles_engine.py

Roles & Compensation Engine:
- يقرأ:
  - ai/memory/offline/sessions/*.json   (إحصائيات step_stats لكل Agent)
  - config/roles.json                   (تعريف الأدوار والمستويات)
- يحسب:
  - عدد مرات التشغيل/النجاح/الفشل لكل Agent
  - نسبة النجاح الكلية
  - مستوى العامل (Junior/Mid/Senior/Expert) حسب thresholds
  - مؤشر راتب salary_index = base_salary_index * level_multiplier
- يكتب:
  - ai/memory/people/agents_levels.json
  - ai/memory/people/agents_levels.txt
"""

import os
import json
from datetime import datetime
from typing import Dict, Any, List, Tuple

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MEMORY_DIR = os.path.join(ROOT, "ai", "memory")
SESSIONS_DIR = os.path.join(MEMORY_DIR, "offline", "sessions")
PEOPLE_DIR = os.path.join(MEMORY_DIR, "people")

CONFIG_ROLES = os.path.join(ROOT, "config", "roles.json")
REPORTS_PEOPLE_DIR = os.path.join(ROOT, "reports", "people")

os.makedirs(PEOPLE_DIR, exist_ok=True)
os.makedirs(REPORTS_PEOPLE_DIR, exist_ok=True)


def load_json_safe(path: str) -> Any:
    if not os.path.isfile(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"⚠️ فشل تحميل JSON من {path}: {e}")
        return None


def load_roles_config() -> Dict[str, Any]:
    cfg = load_json_safe(CONFIG_ROLES)
    if not isinstance(cfg, dict):
        # إعداد افتراضي بسيط في حال غياب الملف
        print("⚠️ لم يتم العثور على config/roles.json أو الملف غير صالح، استخدام إعداد افتراضي.")
        cfg = {
            "levels": {
                "junior": {"label": "مبتدئ", "min_success_rate": 0.70, "multiplier": 0.8},
                "mid": {"label": "متوسط", "min_success_rate": 0.85, "multiplier": 1.0},
                "senior": {"label": "متقدم", "min_success_rate": 0.95, "multiplier": 1.2},
                "expert": {"label": "خبير", "min_success_rate": 0.99, "multiplier": 1.5},
            },
            "roles": {},
            "agents": {},
        }
    return cfg


def discover_sessions() -> List[str]:
    if not os.path.isdir(SESSIONS_DIR):
        return []
    files = []
    for name in os.listdir(SESSIONS_DIR):
        if name.endswith(".json"):
            files.append(os.path.join(SESSIONS_DIR, name))
    return sorted(files)


def aggregate_agent_stats() -> Dict[str, Dict[str, Any]]:
    """
    يقرأ كل ملفات sessions ويجمع step_stats لكل Agent.
    """
    files = discover_sessions()
    if not files:
        print(f"ℹ️ لا توجد ملفات sessions في {SESSIONS_DIR}. لن يتم احتساب إحصائيات.")
        return {}

    agg: Dict[str, Dict[str, Any]] = {}
    total_days = 0

    for path in files:
        data = load_json_safe(path)
        if not isinstance(data, dict):
            continue
        stats = data.get("stats") or {}
        step_stats = stats.get("step_stats") or {}
        if not isinstance(step_stats, dict):
            continue

        total_days += 1
        for agent_name, s in step_stats.items():
            if not isinstance(s, dict):
                continue
            count = int(s.get("count", 0) or 0)
            ok = int(s.get("ok", 0) or 0)
            fail = int(s.get("fail", 0) or 0)

            rec = agg.setdefault(agent_name, {
                "agent": agent_name,
                "total_runs": 0,
                "ok_runs": 0,
                "fail_runs": 0,
                "days_seen": 0,
            })
            rec["total_runs"] += count
            rec["ok_runs"] += ok
            rec["fail_runs"] += fail
            rec["days_seen"] += 1

    # حساب success_rate
    for agent_name, rec in agg.items():
        total = rec.get("total_runs", 0)
        ok = rec.get("ok_runs", 0)
        rec["success_rate"] = (ok / total) if total > 0 else 0.0

    print(f"ℹ️ تم جمع إحصائيات {len(agg)} Agent من {len(files)} ملف sessions (أيام={total_days}).")
    return agg


def determine_level(levels_cfg: Dict[str, Any], success_rate: float) -> Tuple[str, Dict[str, Any]]:
    """
    يختار المستوى المناسب بناءً على success_rate، أعلى threshold مناسبة.
    """
    chosen_id = "junior"
    chosen = {"label": "مبتدئ", "min_success_rate": 0.0, "multiplier": 0.8}

    # ترتيب المستويات حسب min_success_rate تصاعدياً
    items = []
    for lvl_id, info in levels_cfg.items():
        try:
            thr = float(info.get("min_success_rate", 0.0) or 0.0)
        except Exception:
            thr = 0.0
        items.append((thr, lvl_id, info))
    items.sort(key=lambda x: x[0])

    for thr, lvl_id, info in items:
        if success_rate >= thr:
            chosen_id = lvl_id
            chosen = info

    return chosen_id, chosen


def build_agents_levels_report() -> None:
    roles_cfg = load_roles_config()
    levels_cfg = roles_cfg.get("levels", {})
    roles = roles_cfg.get("roles", {})
    agents_cfg = roles_cfg.get("agents", {})

    agg_stats = aggregate_agent_stats()

    agents_output: List[Dict[str, Any]] = []

    for agent_name, stats in sorted(agg_stats.items(), key=lambda x: x[0]):
        meta = agents_cfg.get(agent_name, {})
        role_id = meta.get("role")
        role_info = roles.get(role_id, {})
        base_salary_index = float(role_info.get("base_salary_index", 1.0))

        success_rate = float(stats.get("success_rate", 0.0))
        level_id, level_info = determine_level(levels_cfg, success_rate)
        level_label = level_info.get("label", level_id)
        multiplier = float(level_info.get("multiplier", 1.0))

        salary_index = base_salary_index * multiplier

        agent_record = {
            "agent": agent_name,
            "role_id": role_id,
            "role_title": role_info.get("title"),
            "family": role_info.get("family"),
            "total_runs": stats.get("total_runs", 0),
            "ok_runs": stats.get("ok_runs", 0),
            "fail_runs": stats.get("fail_runs", 0),
            "days_seen": stats.get("days_seen", 0),
            "success_rate": round(success_rate, 4),
            "level_id": level_id,
            "level_label": level_label,
            "base_salary_index": base_salary_index,
            "multiplier": multiplier,
            "salary_index": round(salary_index, 4),
        }
        agents_output.append(agent_record)

    result = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "root": ROOT,
        "sessions_dir": SESSIONS_DIR,
        "roles_config": CONFIG_ROLES,
        "agents_count": len(agents_output),
        "agents": agents_output,
    }

    out_json = os.path.join(PEOPLE_DIR, "agents_levels.json")
    out_txt = os.path.join(PEOPLE_DIR, "agents_levels.txt")

    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    lines: List[str] = []
    lines.append("===== Hyper Factory Agents Levels & Compensation =====")
    lines.append(f"Generated at : {result['generated_at']}")
    lines.append("")
    lines.append(f"Agents count : {len(agents_output)}")
    lines.append("")

    for rec in agents_output:
        sr = rec["success_rate"] * 100.0
        lines.append(f"[{rec['agent']}] ({rec.get('role_title') or rec.get('role_id')})")
        lines.append(f"  - الأسرة        : {rec.get('family')}")
        lines.append(f"  - الأيام المرصودة: {rec['days_seen']}")
        lines.append(f"  - مرات التشغيل  : {rec['total_runs']} (نجاح={rec['ok_runs']}, فشل={rec['fail_runs']})")
        lines.append(f"  - نسبة النجاح   : {sr:.2f}%")
        lines.append(f"  - المستوى       : {rec['level_label']} ({rec['level_id']})")
        lines.append(f"  - مؤشر الراتب   : base={rec['base_salary_index']}, x{rec['multiplier']} => {rec['salary_index']}")
        lines.append("")

    with open(out_txt, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    # كما يمكن إنشاء تقرير للأشخاص تحت reports/people
    rep_path = os.path.join(REPORTS_PEOPLE_DIR, "agents_levels_overview.txt")
    with open(rep_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print("✅ تم توليد تقارير مستويات ورواتب الـ Agents:")
    print(f"   - {out_json}")
    print(f"   - {out_txt}")
    print(f"   - {rep_path}")


def main() -> None:
    print(f"📁 ROOT        : {ROOT}")
    print(f"📂 SESSIONS_DIR: {SESSIONS_DIR}")
    print(f"📄 ROLES_CFG   : {CONFIG_ROLES}")
    print(f"📂 PEOPLE_DIR  : {PEOPLE_DIR}")
    print("----------------------------------------")
    build_agents_levels_report()


if __name__ == "__main__":
    main()
