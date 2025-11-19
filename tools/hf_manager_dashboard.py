#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
hf_manager_dashboard.py

Manager Dashboard:
- يقرأ مخرجات المصنع الحالية:
  1) أداء الـ pipeline:
     - data/report/summary_basic.json   (إحصائيات الدورات)
  2) الدروس المستفادة:
     - ai/memory/lessons/*.json         (Actions)
  3) المناهج والـ Phases:
     - ai/memory/curriculum/roadmap.json
  4) مستويات ورواتب الـ Agents:
     - ai/memory/people/agents_levels.json

- ينتج تقرير تنفيذي لمدير المصنع:
  - reports/management/{timestamp}_manager_daily_overview.txt
  - reports/management/{timestamp}_manager_daily_overview.json

لا يقوم بأي تعديل على config/ أو أي ملف تشغيل.
"""

import json
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

ROOT = Path("/root/hyper-factory").resolve()
REPORTS_MGMT_DIR = ROOT / "reports" / "management"
SUMMARY_BASIC_PATH = ROOT / "data" / "report" / "summary_basic.json"
ROADMAP_PATH = ROOT / "ai" / "memory" / "curriculum" / "roadmap.json"
LESSONS_DIR = ROOT / "ai" / "memory" / "lessons"
AGENTS_LEVELS_PATH = ROOT / "ai" / "memory" / "people" / "agents_levels.json"


# ========= أدوات مساعدة عامة =========

def load_json(path: Path) -> Optional[Dict[str, Any]]:
    if not path.is_file():
        return None
    try:
        with path.open("r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        print(f"⚠️ فشل قراءة JSON من {path}: {e}")
        return None


def format_pct(val: Any) -> str:
    try:
        f = float(val)
        # لو القيمة بين 0 و 1 نفترض أنها ratio
        if 0.0 <= f <= 1.0:
            return f"{f*100:.2f}%"
        return f"{f:.2f}%"
    except Exception:
        return "N/A"


# ========= 1) KPIs من summary_basic =========

def load_summary_basic() -> Dict[str, Any]:
    data = load_json(SUMMARY_BASIC_PATH)
    if not data:
        return {}

    result: Dict[str, Any] = {}

    # إجمالي الدورات
    for key in ("total_runs", "runs_total", "total"):
        if key in data:
            result["total_runs"] = data[key]
            break

    # الناجحة
    for key in ("success_runs", "runs_success", "ok_runs"):
        if key in data:
            result["success_runs"] = data[key]
            break

    # الفاشلة
    for key in ("failed_runs", "runs_failed", "error_runs"):
        if key in data:
            result["failed_runs"] = data[key]
            break

    # متوسط النجاح
    for key in ("avg_success_rate", "success_rate"):
        if key in data:
            result["avg_success_rate"] = data[key]
            break

    # عدد الأيام
    if "days_count" in data:
        result["days_count"] = data["days_count"]

    result["_raw"] = data
    return result


# ========= 2) الدروس المستفادة من lessons/*.json =========

def normalize_actions_from_file(payload: Any, default_date: Optional[str]) -> List[Dict[str, Any]]:
    """
    نحاول استخراج قائمة Actions من أي شكل محتمل:
    - {"actions": [ {...}, {...} ]}
    - [ {...}, {...} ]
    - {"id": "...", "title": "..."}  ← Action مفرد
    """
    actions: List[Dict[str, Any]] = []

    if isinstance(payload, dict):
        # case: {"actions": [...]}
        if isinstance(payload.get("actions"), list):
            base_date = payload.get("date") or default_date
            for a in payload["actions"]:
                if isinstance(a, dict):
                    a = dict(a)
                    a.setdefault("date", base_date)
                    actions.append(a)
            return actions

        # case: dict مفرد يمثل Action واحدة
        if "id" in payload or "title" in payload:
            a = dict(payload)
            a.setdefault("date", payload.get("date") or default_date)
            actions.append(a)
            return actions

    # case: list of actions
    if isinstance(payload, list):
        for a in payload:
            if isinstance(a, dict):
                a = dict(a)
                a.setdefault("date", default_date)
                actions.append(a)

    return actions


def load_lessons(lessons_dir: Path) -> List[Dict[str, Any]]:
    if not lessons_dir.is_dir():
        print(f"ℹ️ لا يوجد مجلد للدروس: {lessons_dir}")
        return []

    files = sorted(lessons_dir.glob("*.json"))
    if not files:
        print(f"ℹ️ لا توجد ملفات Lessons في: {lessons_dir}")
        return []

    all_actions: List[Dict[str, Any]] = []
    for fp in files:
        payload = load_json(fp)
        if not payload:
            continue

        # استنتاج التاريخ من اسم الملف (مثلاً 2025-11-19_lessons.json)
        default_date = None
        stem = fp.stem
        if "_" in stem:
            maybe_date = stem.split("_", 1)[0]
            default_date = maybe_date

        actions = normalize_actions_from_file(payload, default_date)
        for a in actions:
            a.setdefault("source_file", str(fp))
        all_actions.extend(actions)

    # ترتيب بسيط حسب التاريخ إن وجد
    def _sort_key(a: Dict[str, Any]) -> str:
        return str(a.get("date") or "") + "_" + str(a.get("id") or "")

    all_actions.sort(key=_sort_key)
    return all_actions


# ========= 3) المناهج والـ Phases من roadmap.json =========

def load_curriculum(roadmap_path: Path) -> Dict[str, Any]:
    data = load_json(roadmap_path)
    return data or {}


def summarize_curriculum_phases(curriculum: Dict[str, Any]) -> Tuple[str, List[Tuple[str, str]]]:
    phases = curriculum.get("phases") or []
    summaries: List[Tuple[str, str]] = []
    for ph in phases:
        title = ph.get("title", "بدون عنوان")
        desc = (ph.get("description") or "").strip()
        summaries.append((title, desc))

    current_phase = phases[0]["title"] if phases else "غير محدد"
    return current_phase, summaries


# ========= 4) مستويات ورواتب الـ Agents =========

def normalize_agents_struct(raw: Any) -> List[Dict[str, Any]]:
    """
    يدعم:
    - {"agents": [ {...}, {...} ]}
    - [ {...}, {...} ]
    - {"ingestor_basic": {...}, "analyzer_basic": {...}}
    """
    agents: List[Dict[str, Any]] = []

    if isinstance(raw, list):
        for item in raw:
            if isinstance(item, dict):
                agents.append(item)
        return agents

    if isinstance(raw, dict):
        if isinstance(raw.get("agents"), list):
            for item in raw["agents"]:
                if isinstance(item, dict):
                    agents.append(item)
            return agents

        # dict keyed by agent name
        candidate: List[Dict[str, Any]] = []
        for k, v in raw.items():
            if isinstance(v, dict):
                item = {"name": k}
                item.update(v)
                candidate.append(item)
        if candidate:
            return candidate

    return []


def load_agents_levels(path: Path) -> List[Dict[str, Any]]:
    data = load_json(path)
    if not data:
        return []

    raw_agents = normalize_agents_struct(data)
    normalized: List[Dict[str, Any]] = []

    for a in raw_agents:
        name = a.get("name") or a.get("agent_name") or a.get("id") or "unknown"
        family = a.get("family") or a.get("group") or "unknown"
        success_rate = a.get("success_rate", None)
        level = a.get("level") or a.get("level_name") or "unknown"
        salary_index = a.get("salary_index") or a.get("salary_factor") or None
        runs = a.get("total_runs") or a.get("runs") or None
        days = a.get("days_count") or a.get("days") or None

        normalized.append(
            {
                "name": name,
                "family": family,
                "success_rate": success_rate,
                "level": level,
                "salary_index": salary_index,
                "total_runs": runs,
                "days_count": days,
                "_raw": a,
            }
        )

    return normalized


# ========= 5) بناء تقرير مدير المصنع =========

def build_manager_report(
    summary_basic: Dict[str, Any],
    lessons: List[Dict[str, Any]],
    curriculum: Dict[str, Any],
    agents_levels: List[Dict[str, Any]],
) -> str:
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")

    total_runs = summary_basic.get("total_runs", "N/A")
    success_runs = summary_basic.get("success_runs", "N/A")
    failed_runs = summary_basic.get("failed_runs", "N/A")
    avg_success_rate = summary_basic.get("avg_success_rate", None)
    days_count = summary_basic.get("days_count", None)
    success_str = format_pct(avg_success_rate) if avg_success_rate is not None else "N/A"

    # تقييم حالة الاستقرار
    status_note = "لا يمكن تقييم الاستقرار (بيانات غير مكتملة)"
    try:
        if avg_success_rate is not None:
            v = float(avg_success_rate)
            if v >= 0.99:
                status_note = "استقرار ممتاز (Baseline مناسب للتوسّع)."
            elif v >= 0.95:
                status_note = "استقرار جيد مع مساحة لتحسينات صغيرة."
            elif v >= 0.85:
                status_note = "استقرار متوسط – يفضّل مراقبة مستمرة وتحسين تدريجي."
            else:
                status_note = "استقرار منخفض – يفضّل مراجعة أسباب الإخفاق."
    except Exception:
        pass

    # Curriculum
    current_phase, phases_list = summarize_curriculum_phases(curriculum)

    # مقتطف من أهم الدروس (limit)
    lessons_lines: List[str] = []
    max_lessons = 5
    for idx, a in enumerate(lessons[:max_lessons], start=1):
        lid = a.get("id", f"action_{idx}")
        title = a.get("title", "بدون عنوان")
        prio = a.get("priority", "UNSPECIFIED")
        date = a.get("date", "N/A")
        desc = a.get("description", "")
        if isinstance(desc, list):
            desc = " ".join(str(x) for x in desc)
        lessons_lines.append(
            f"[{idx}] id={lid} | priority={prio} | date={date}\n"
            f"    title: {title}\n"
            f"    desc : {desc}"
        )

    # Agents summary lines
    agents_lines: List[str] = []
    for a in agents_levels:
        sr = format_pct(a.get("success_rate"))
        agents_lines.append(
            f"- {a['name']} [{a['family']}]: "
            f"النجاح={sr}, المستوى={a['level']}, مؤشر الراتب={a['salary_index']}"
        )

    # مهام تنفيذية مقترحة
    action_items: List[str] = []

    # Stable day → توثيق Baseline
    try:
        if avg_success_rate is not None and float(avg_success_rate) >= 0.99:
            action_items.append(
                "- توثيق إعدادات اليوم (الكود + config + بيئة السيرفر) كـ Baseline stable في Git/وثيقة مستقلة."
            )
    except Exception:
        pass

    # Phase زيادة الحمل من الـ curriculum
    if "زيادة الحمل" in current_phase:
        action_items.append(
            "- زيادة عدد الدورات أو إضافة مصادر بيانات جديدة تدريجيًا مع مراقبة KPIs وملف quality.json."
        )

    # Lessons موجودة → مراجعة config_changes يدويًا
    if lessons:
        action_items.append(
            "- مراجعة آخر ملفات config_changes (agents.diff / factory.diff) واعتماد التعديلات المناسبة يدويًا."
        )

    # Agents ليسوا كلهم experts (مستقبلًا)
    non_experts = [
        a for a in agents_levels if str(a.get("level", "")).lower() not in ("expert", "خبير")
    ]
    if non_experts:
        names = ", ".join(a["name"] for a in non_experts)
        action_items.append(
            f"- تصميم خطة تطوير/تدريب للـ Agents التالية: {names}."
        )

    # خطوة ثابتة: استمرار دورات basic مع الذاكرة
    action_items.append(
        "- الاستمرار في تشغيل run_basic_with_memory.sh بانتظام لضمان تراكم الذاكرة (messages/lessons/metrics)."
    )

    # نص التقرير
    lines: List[str] = []
    lines.append("===== Hyper Factory – Manager Daily Overview =====")
    lines.append(f"Generated at : {now}")
    lines.append("")
    lines.append("== 1) حالة المصنع العامة (KPIs) ==")
    lines.append(f"- عدد الأيام المرصودة        : {days_count if days_count is not None else 'N/A'}")
    lines.append(f"- إجمالي عدد الدورات        : {total_runs}")
    lines.append(f"- عدد الدورات الناجحة        : {success_runs}")
    lines.append(f"- عدد الدورات الفاشلة        : {failed_runs}")
    lines.append(f"- متوسط نسبة النجاح          : {success_str}")
    lines.append(f"- ملاحظة حالة الاستقرار      : {status_note}")
    lines.append("")

    lines.append("== 2) الدروس المستفادة (Top Lessons Snapshot) ==")
    if lessons_lines:
        for ln in lessons_lines:
            lines.append(ln)
    else:
        lines.append("- لا توجد دروس مسجّلة حتى الآن (ai/memory/lessons فارغ).")
    lines.append("")

    lines.append("== 3) مستويات العمال الآليين (Agents Levels & Compensation) ==")
    if agents_lines:
        lines.extend(agents_lines)
    else:
        lines.append("- لا توجد بيانات عن مستويات الـ Agents (agents_levels.json غير متوفر أو فارغ).")
    lines.append("")

    lines.append("== 4) مرحلة المناهج والتطوّر (Curriculum Phases) ==")
    lines.append(f"- المرحلة الحالية المتوقعة : {current_phase}")
    if phases_list:
        lines.append("- المراحل المسجّلة:")
        for title, desc in phases_list:
            lines.append(f"  * {title}: {desc}")
    else:
        lines.append("- لا توجد مراحل مسجّلة في roadmap.json.")
    lines.append("")

    lines.append("== 5) قائمة المهام المقترحة لمدير المصنع (Action List) ==")
    if action_items:
        for item in action_items:
            lines.append(item)
    else:
        lines.append("- لا توجد مهام مقترحة محددة حالياً؛ يمكن الاكتفاء بالمراقبة.")
    lines.append("")

    return "\n".join(lines)


# ========= main =========

def main() -> None:
    print(f"📁 ROOT        : {ROOT}")
    REPORTS_MGMT_DIR.mkdir(parents=True, exist_ok=True)

    summary_basic = load_summary_basic()
    lessons = load_lessons(LESSONS_DIR)
    curriculum = load_curriculum(ROADMAP_PATH)
    agents_levels = load_agents_levels(AGENTS_LEVELS_PATH)

    report_text = build_manager_report(
        summary_basic=summary_basic,
        lessons=lessons,
        curriculum=curriculum,
        agents_levels=agents_levels,
    )

    ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    txt_path = REPORTS_MGMT_DIR / f"{ts}_manager_daily_overview.txt"
    json_path = REPORTS_MGMT_DIR / f"{ts}_manager_daily_overview.json"

    # حفظ التقرير النصي
    with txt_path.open("w", encoding="utf-8") as f:
        f.write(report_text)

    # JSON تنفيذي مختصر
    payload = {
        "generated_at": ts,
        "summary_basic": summary_basic,
        "lessons_count": len(lessons),
        "curriculum_current_phase": summarize_curriculum_phases(curriculum)[0],
        "agents_count": len(agents_levels),
    }
    try:
        with json_path.open("w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"⚠️ فشل حفظ JSON الخاص بتقرير الإدارة: {e}")

    print("----------------------------------------")
    print("✅ تم توليد تقرير مدير المصنع:")
    print(f"   - {txt_path}")
    print(f"   - {json_path}")


if __name__ == "__main__":
    main()
