#!/usr/bin/env python3
"""
tools/hf_technical_coach.py

Technical Coach Worker:
- يقرأ:
  - ai/memory/offline/sessions/*.json
  - ai/memory/offline/patterns/*.json
  - ai/memory/lessons/*.json
  - design/goals.json (اختياري)
- يبني منهج تعلّم (Curriculum / Roadmap) لـ Hyper Factory:
  - مراحل/Fases عالية المستوى
  - مؤشرات أداء عامة لكل الأيام
- يكتب:
  - ai/memory/curriculum/roadmap.json
  - ai/memory/curriculum/roadmap.txt
"""

import os
import json
from datetime import datetime
from typing import Dict, Any, List, Optional, Tuple

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MEMORY_DIR = os.path.join(ROOT, "ai", "memory")
OFFLINE_DIR = os.path.join(MEMORY_DIR, "offline")
SESSIONS_DIR = os.path.join(OFFLINE_DIR, "sessions")
PATTERNS_DIR = os.path.join(OFFLINE_DIR, "patterns")
LESSONS_DIR = os.path.join(MEMORY_DIR, "lessons")

CURRICULUM_DIR = os.path.join(MEMORY_DIR, "curriculum")
MODULES_DIR = os.path.join(CURRICULUM_DIR, "modules")

GOALS_JSON = os.path.join(ROOT, "design", "goals.json")

ROADMAP_JSON = os.path.join(CURRICULUM_DIR, "roadmap.json")
ROADMAP_TXT = os.path.join(CURRICULUM_DIR, "roadmap.txt")


def ensure_dirs() -> None:
    os.makedirs(CURRICULUM_DIR, exist_ok=True)
    os.makedirs(MODULES_DIR, exist_ok=True)


def load_json(path: str) -> Optional[Dict[str, Any]]:
    if not os.path.exists(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def load_sessions() -> Dict[str, Dict[str, Any]]:
    sessions: Dict[str, Dict[str, Any]] = {}
    if not os.path.isdir(SESSIONS_DIR):
        return sessions

    for fname in os.listdir(SESSIONS_DIR):
        if not fname.endswith(".json"):
            continue
        path = os.path.join(SESSIONS_DIR, fname)
        data = load_json(path)
        if not data:
            continue
        date = data.get("date") or os.path.splitext(fname)[0]
        sessions[date] = data
    return sessions


def load_patterns() -> Dict[str, Dict[str, Any]]:
    patterns: Dict[str, Dict[str, Any]] = {}
    if not os.path.isdir(PATTERNS_DIR):
        return patterns

    for fname in os.listdir(PATTERNS_DIR):
        if not fname.endswith(".json"):
            continue
        path = os.path.join(PATTERNS_DIR, fname)
        data = load_json(path)
        if not data:
            continue
        # نحاول استخراج التاريخ من الاسم
        base = os.path.splitext(fname)[0]  # مثال: 2025-11-19_patterns
        date = base.split("_")[0]
        patterns[date] = data
    return patterns


def load_lessons() -> Dict[str, Dict[str, Any]]:
    lessons: Dict[str, Dict[str, Any]] = {}
    if not os.path.isdir(LESSONS_DIR):
        return lessons

    for fname in os.listdir(LESSONS_DIR):
        if not fname.endswith(".json"):
            continue
        path = os.path.join(LESSONS_DIR, fname)
        data = load_json(path)
        if not data:
            continue
        date = data.get("date") or os.path.splitext(fname)[0].split("_")[0]
        lessons[date] = data
    return lessons


def aggregate_metrics(sessions: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
    days = sorted(sessions.keys())
    if not days:
        return {
            "days_count": 0,
            "total_runs": 0,
            "success_runs": 0,
            "failed_runs": 0,
            "avg_success_rate": None,
            "days_with_failures": [],
        }

    total_runs = 0
    success_runs = 0
    failed_runs = 0
    success_rates: List[float] = []
    days_with_failures: List[str] = []

    for date, s in sessions.items():
        stats = s.get("stats", {})
        tr = stats.get("total_runs", 0)
        sr = stats.get("success_runs", 0)
        fr = stats.get("failed_runs", 0)
        rate = stats.get("success_rate", None)

        total_runs += tr
        success_runs += sr
        failed_runs += fr
        if isinstance(rate, (int, float)):
            success_rates.append(rate)

        if fr and fr > 0:
            days_with_failures.append(date)

    avg_success_rate = None
    if success_rates:
        avg_success_rate = sum(success_rates) / len(success_rates)

    return {
        "days_count": len(days),
        "days": days,
        "total_runs": total_runs,
        "success_runs": success_runs,
        "failed_runs": failed_runs,
        "avg_success_rate": avg_success_rate,
        "days_with_failures": days_with_failures,
    }


def build_phases(metrics: Dict[str, Any],
                 sessions: Dict[str, Dict[str, Any]],
                 patterns: Dict[str, Dict[str, Any]],
                 lessons: Dict[str, Dict[str, Any]],
                 goals: Optional[Dict[str, Any]]) -> List[Dict[str, Any]]:
    phases: List[Dict[str, Any]] = []

    days_count = metrics.get("days_count", 0)
    total_runs = metrics.get("total_runs", 0)
    failed_runs = metrics.get("failed_runs", 0)
    avg_success_rate = metrics.get("avg_success_rate", None)
    days_with_failures = metrics.get("days_with_failures", [])

    # Phase 1: Stabilization أو تثبيت الخط
    if days_count == 0 or total_runs == 0:
        phases.append({
            "id": "phase_collect_data",
            "title": "جمع بيانات تشغيل كافية",
            "priority": "HIGH",
            "description": (
                "لا توجد بيانات جلسات Offline كافية بعد. "
                "يُفضّل تشغيل عدد أكبر من الدورات عبر run_basic_with_memory.sh "
                "ثم تشغيل hf_run_offline_learner.sh لبناء sessions/patterns/lessons."
            ),
            "scope": "pipeline",
        })
        return phases

    if failed_runs == 0:
        phases.append({
            "id": "phase_stable_reference",
            "title": "مرحلة المرجع المستقر",
            "priority": "MEDIUM",
            "description": (
                f"كل الأيام المسجّلة ({days_count}) بدون فشل (failed_runs=0). "
                "يمكن اعتبار هذه الفترة مرجعًا لاستقرار Hyper Factory، "
                "مع توثيق إصدارات الكود وإعدادات السيرفر."
            ),
            "scope": "pipeline",
        })
    else:
        phases.append({
            "id": "phase_fix_failures",
            "title": "مرحلة معالجة الفشل",
            "priority": "HIGH",
            "description": (
                f"تم رصد {failed_runs} تشغيلات فاشلة على مدى {days_count} يوم. "
                f"أيام بها فشل: {', '.join(days_with_failures) if days_with_failures else 'غير محددة'}. "
                "الخطوة القادمة هي ربط هذه الأيام بتقارير Debug Expert ومعالجة أسباب الفشل."
            ),
            "scope": "pipeline",
        })

    # Phase 2: Scaling
    if avg_success_rate is not None and avg_success_rate >= 0.95:
        phases.append({
            "id": "phase_scale_usage",
            "title": "مرحلة زيادة الحمل بشكل آمن",
            "priority": "MEDIUM",
            "description": (
                f"متوسط نسبة النجاح عبر الأيام ≈ {avg_success_rate:.2%}. "
                "يمكن زيادة عدد الدورات أو إدخال مصادر بيانات جديدة تدريجيًا "
                "مع استمرار مراقبة quality و smart_actions."
            ),
            "scope": "throughput",
        })

    # Phase 3: Knowledge & Lessons
    total_lessons = sum(len(v.get("actions", [])) for v in lessons.values())
    phases.append({
        "id": "phase_leverage_lessons",
        "title": "مرحلة تفعيل الدروس المستفادة",
        "priority": "MEDIUM",
        "description": (
            f"تم تسجيل {total_lessons} درس/Actionable في ai/memory/lessons/*.json. "
            "الخطوة التالية هي تحويل هذه الدروس إلى تغييرات ملموسة في "
            "config/agents.yaml أو factory.yaml عبر مراجعات بشرية و/أو سكربت apply-lessons لاحقًا."
        ),
        "scope": "learning",
    })

    # Phase 4: Goals Alignment (لو فيه design/goals.json)
    if goals:
        goals_summary = goals.get("summary") or goals.get("description") or ""
        phases.append({
            "id": "phase_goals_alignment",
            "title": "مواءمة التشغيل مع الأهداف المستقبلية",
            "priority": "MEDIUM",
            "description": (
                "ملف design/goals.json موجود. "
                "يجب مقارنة أداء الأيام السابقة مع هذه الأهداف وتحديد الفجوات."
                + (f" ملخص الأهداف: {goals_summary}" if goals_summary else "")
            ),
            "scope": "strategy",
        })

    return phases


def build_roadmap_text(roadmap: Dict[str, Any]) -> str:
    lines: List[str] = []
    lines.append("===== Hyper Factory Technical Curriculum Roadmap =====")
    lines.append(f"Generated at : {roadmap.get('generated_at', '')}")
    lines.append("")
    metrics = roadmap.get("metrics", {})
    lines.append("== Metrics Summary ==")
    lines.append(f"- Days count    : {metrics.get('days_count')}")
    lines.append(f"- Total runs    : {metrics.get('total_runs')}")
    lines.append(f"- Failed runs   : {metrics.get('failed_runs')}")
    avg_sr = metrics.get("avg_success_rate")
    if avg_sr is not None:
        lines.append(f"- Avg success   : {avg_sr:.2%}")
    lines.append("")
    lines.append("== Phases ==")
    phases = roadmap.get("phases", [])
    for idx, p in enumerate(phases, start=1):
        lines.append(f"[{idx}] {p.get('title')} (id={p.get('id')}, priority={p.get('priority')})")
        lines.append(f"    scope : {p.get('scope')}")
        desc = p.get("description", "").replace("\n", " ")
        lines.append(f"    desc  : {desc}")
        lines.append("")
    return "\n".join(lines)


def main() -> None:
    print(f"📁 ROOT        : {ROOT}")
    print(f"📂 SESSIONS_DIR: {SESSIONS_DIR}")
    print(f"📂 PATTERNS_DIR: {PATTERNS_DIR}")
    print(f"📂 LESSONS_DIR : {LESSONS_DIR}")
    print("----------------------------------------")

    ensure_dirs()

    sessions = load_sessions()
    patterns = load_patterns()
    lessons = load_lessons()
    goals = load_json(GOALS_JSON)

    metrics = aggregate_metrics(sessions)
    phases = build_phases(metrics, sessions, patterns, lessons, goals)

    roadmap: Dict[str, Any] = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "metrics": metrics,
        "phases": phases,
        "references": {
            "sessions_files": sorted(os.listdir(SESSIONS_DIR)) if os.path.isdir(SESSIONS_DIR) else [],
            "patterns_files": sorted(os.listdir(PATTERNS_DIR)) if os.path.isdir(PATTERNS_DIR) else [],
            "lessons_files": sorted(os.listdir(LESSONS_DIR)) if os.path.isdir(LESSONS_DIR) else [],
            "goals_file": GOALS_JSON if os.path.exists(GOALS_JSON) else None,
        },
    }

    # كتابة JSON
    with open(ROADMAP_JSON, "w", encoding="utf-8") as f:
        json.dump(roadmap, f, ensure_ascii=False, indent=2)

    # كتابة TXT
    txt = build_roadmap_text(roadmap)
    with open(ROADMAP_TXT, "w", encoding="utf-8") as f:
        f.write(txt)

    print("✅ تم توليد Roadmap للمناهج:")
    print(f"   - {ROADMAP_JSON}")
    print(f"   - {ROADMAP_TXT}")


if __name__ == "__main__":
    main()
