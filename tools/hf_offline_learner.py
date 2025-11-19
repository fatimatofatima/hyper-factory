#!/usr/bin/env python3
"""
tools/hf_offline_learner.py

Offline Learner:
- يقرأ ai/memory/messages.jsonl (أحداث الدورات)
- يجمعها حسب اليوم (YYYY-MM-DD)
- يحسب:
  - إجمالي الدورات / الناجح / الفاشل / نسبة النجاح
  - إحصائيات لكل عامل (ingestor_basic, processor_basic, analyzer_basic, reporter_basic)
  - أنماط بسيطة للفشل (إن وجدت)
- يكتب:
  - ai/memory/offline/sessions/{date}.json
  - ai/memory/offline/patterns/{date}_patterns.json
  - ai/memory/lessons/{date}_lessons.json
"""

import os
import json
from datetime import datetime
from typing import Dict, Any, List, Optional

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEMORY_DIR = os.path.join(ROOT, "ai", "memory")
MESSAGES_PATH = os.path.join(MEMORY_DIR, "messages.jsonl")

OFFLINE_DIR = os.path.join(MEMORY_DIR, "offline")
SESSIONS_DIR = os.path.join(OFFLINE_DIR, "sessions")
PATTERNS_DIR = os.path.join(OFFLINE_DIR, "patterns")
LESSONS_DIR = os.path.join(MEMORY_DIR, "lessons")


def ensure_dirs() -> None:
    os.makedirs(MEMORY_DIR, exist_ok=True)
    os.makedirs(OFFLINE_DIR, exist_ok=True)
    os.makedirs(SESSIONS_DIR, exist_ok=True)
    os.makedirs(PATTERNS_DIR, exist_ok=True)
    os.makedirs(LESSONS_DIR, exist_ok=True)


def parse_timestamp(value: Any) -> Optional[datetime]:
    """
    يحاول قراءة الطابع الزمني من عدة أشكال:
    - "2025-11-19T04:40:11Z"
    - "2025-11-19T01:43:18.103426Z"
    - "2025-11-19 04:43:17"
    """
    if value is None:
        return None
    if isinstance(value, datetime):
        return value

    s = str(value).strip()
    for fmt in (
        "%Y-%m-%dT%H:%M:%S.%fZ",
        "%Y-%m-%dT%H:%M:%S.%f",
        "%Y-%m-%dT%H:%M:%SZ",
        "%Y-%m-%dT%H:%M:%S",
        "%Y-%m-%d %H:%M:%S",
    ):
        try:
            return datetime.strptime(s, fmt)
        except ValueError:
            continue
    return None


def load_events() -> List[Dict[str, Any]]:
    events: List[Dict[str, Any]] = []
    if not os.path.exists(MESSAGES_PATH):
        return events

    with open(MESSAGES_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            events.append(obj)
    return events


def group_by_day(events: List[Dict[str, Any]]) -> Dict[str, List[Dict[str, Any]]]:
    grouped: Dict[str, List[Dict[str, Any]]] = {}
    for ev in events:
        ts_raw = ev.get("timestamp") or ev.get("timestamp_str")
        dt = parse_timestamp(ts_raw)
        if dt is None:
            # fallback: اليوم غير معروف ⇒ نضعه تحت "unknown"
            key = "unknown"
        else:
            key = dt.date().isoformat()
        grouped.setdefault(key, []).append(ev)
    return grouped


def compute_daily_stats(day_events: List[Dict[str, Any]]) -> Dict[str, Any]:
    total_runs = len(day_events)
    success_runs = 0
    failed_runs = 0

    step_stats: Dict[str, Dict[str, Any]] = {}

    for ev in day_events:
        success = bool(ev.get("success", False))
        if success:
            success_runs += 1
        else:
            failed_runs += 1

        steps: Dict[str, str] = ev.get("steps", {})
        for name, status in steps.items():
            s = step_stats.setdefault(
                name,
                {"count": 0, "ok": 0, "fail": 0, "last_status": None},
            )
            s["count"] += 1
            if status.upper() == "OK":
                s["ok"] += 1
            else:
                s["fail"] += 1
            s["last_status"] = status

    success_rate = (success_runs / total_runs) if total_runs > 0 else 0.0

    return {
        "total_runs": total_runs,
        "success_runs": success_runs,
        "failed_runs": failed_runs,
        "success_rate": success_rate,
        "step_stats": step_stats,
    }


def build_patterns(day: str, stats: Dict[str, Any]) -> Dict[str, Any]:
    step_stats: Dict[str, Dict[str, Any]] = stats.get("step_stats", {})
    patterns: Dict[str, Any] = {
        "date": day,
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "notes": [],
        "step_risks": [],
    }

    total_runs = stats.get("total_runs", 0)
    failed_runs = stats.get("failed_runs", 0)
    success_rate = stats.get("success_rate", 0.0)

    if total_runs == 0:
        patterns["notes"].append("لا توجد دورات في هذا اليوم.")
        return patterns

    if failed_runs == 0:
        patterns["notes"].append(
            "كل الدورات في هذا اليوم ناجحة. يمكن اعتبار هذا اليوم مرجعًا للاستقرار."
        )
    else:
        patterns["notes"].append(
            f"تم رصد فشل في {failed_runs} من {total_runs} دورة في هذا اليوم."
        )

    for name, st in step_stats.items():
        count = st.get("count", 0)
        fail = st.get("fail", 0)
        ok = st.get("ok", 0)

        fail_rate = (fail / count) if count > 0 else 0.0

        if fail == 0:
            risk = "LOW"
        elif fail_rate < 0.25:
            risk = "MEDIUM"
        else:
            risk = "HIGH"

        patterns["step_risks"].append(
            {
                "step": name,
                "count": count,
                "ok": ok,
                "fail": fail,
                "fail_rate": fail_rate,
                "risk": risk,
            }
        )

    patterns["summary"] = {
        "total_runs": total_runs,
        "failed_runs": failed_runs,
        "success_rate": success_rate,
    }

    return patterns


def build_lessons(day: str, stats: Dict[str, Any], patterns: Dict[str, Any]) -> Dict[str, Any]:
    """
    يبني دروس Actionable بسيطة من إحصائيات اليوم.
    """
    lessons: Dict[str, Any] = {
        "date": day,
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "actions": [],
    }

    total_runs = stats.get("total_runs", 0)
    failed_runs = stats.get("failed_runs", 0)
    success_rate = stats.get("success_rate", 0.0)
    step_risks: List[Dict[str, Any]] = patterns.get("step_risks", [])

    # حالة بدون بيانات
    if total_runs == 0:
        lessons["actions"].append(
            {
                "id": "no_data_for_day",
                "title": "لا توجد بيانات لهذا اليوم",
                "priority": "LOW",
                "description": "لم يتم تسجيل أي دورات في هذا اليوم. يُفضّل تشغيل عدد من الدورات وجمع بيانات قبل استخلاص دروس.",
            }
        )
        return lessons

    # حالة نجاح عالي
    if failed_runs == 0 and total_runs >= 5:
        lessons["actions"].append(
            {
                "id": "stable_day_reference",
                "title": "يوم مستقر - مرجع جيد",
                "priority": "MEDIUM",
                "description": "جميع الدورات في هذا اليوم ناجحة. يمكن استخدام إعدادات هذا اليوم كمرجع للاستقرار وتوثيق البيئة (إصدارات الكود، إعدادات السيرفر).",
            }
        )

    # عتبات بسيطة للفشل
    if failed_runs > 0:
        if success_rate < 0.9:
            priority = "HIGH"
        else:
            priority = "MEDIUM"

        lessons["actions"].append(
            {
                "id": "review_failed_runs",
                "title": "مراجعة الدورات الفاشلة في هذا اليوم",
                "priority": priority,
                "description": f"تم رصد {failed_runs} دورة فاشلة من أصل {total_runs}. يُنصح بمراجعة اللوجات المرتبطة بهذه الدورات (basic_runs.log وreports/debug_*/).",
            }
        )

    # دروس لكل عامل عالي المخاطر
    for step_info in step_risks:
        if step_info.get("risk") in ("HIGH", "MEDIUM") and step_info.get("fail", 0) > 0:
            step = step_info.get("step")
            fail = step_info.get("fail")
            fail_rate = step_info.get("fail_rate", 0.0)

            lessons["actions"].append(
                {
                    "id": f"focus_{step}",
                    "title": f"تركيز تحليل على العامل {step}",
                    "priority": "HIGH" if step_info["risk"] == "HIGH" else "MEDIUM",
                    "description": (
                        f"العامل {step} لديه {fail} حالات فشل في هذا اليوم "
                        f"(نسبة فشل تقريبية: {fail_rate:.2%}). يُنصح بمراجعة كود هذا العامل "
                        "وتحسين التعامل مع الحالات الشاذة، وربط النتائج مع Debug Expert."
                    ),
                }
            )

    # لو النجاح عالي جدًا يمكن اقتراح التوسع
    if failed_runs == 0 and total_runs >= 10:
        lessons["actions"].append(
            {
                "id": "scale_confidently",
                "title": "إمكانية زيادة الحمل بثقة",
                "priority": "MEDIUM",
                "description": "معدل النجاح مرتفع وعدد الدورات كافٍ. يمكن زيادة عدد الدورات أو إدخال مصادر بيانات إضافية، مع استمرار مراقبة الجودة.",
            }
        )

    return lessons


def write_json(path: str, obj: Any) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)


def main() -> None:
    print(f"📁 ROOT       : {ROOT}")
    print(f"📂 MEMORY_DIR : {MEMORY_DIR}")
    print(f"📄 MESSAGES   : {MESSAGES_PATH}")
    print("----------------------------------------")

    ensure_dirs()
    events = load_events()

    if not events:
        print("ℹ️ لا توجد أحداث في messages.jsonl بعد. لا يوجد ما يتم تعلمه Offline.")
        # نكتب ملفات فارغة رمزية
        empty_summary = {
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "note": "no_events_yet",
        }
        write_json(os.path.join(OFFLINE_DIR, "offline_empty_summary.json"), empty_summary)
        return

    grouped = group_by_day(events)
    print(f"ℹ️ عدد الأيام في الذاكرة: {len(grouped)}")

    for day, day_events in grouped.items():
        print(f"--- معالجة اليوم: {day} ({len(day_events)} حدث) ---")
        stats = compute_daily_stats(day_events)
        patterns = build_patterns(day, stats)
        lessons = build_lessons(day, stats, patterns)

        session_path = os.path.join(SESSIONS_DIR, f"{day}.json")
        patterns_path = os.path.join(PATTERNS_DIR, f"{day}_patterns.json")
        lessons_path = os.path.join(LESSONS_DIR, f"{day}_lessons.json")

        write_json(session_path, {"date": day, "stats": stats, "events_count": len(day_events)})
        write_json(patterns_path, patterns)
        write_json(lessons_path, lessons)

        print(f"✅ كتبنا session:  {session_path}")
        print(f"✅ كتبنا patterns: {patterns_path}")
        print(f"✅ كتبنا lessons:  {lessons_path}")

    print("✅ انتهى Offline Learner: تم بناء sessions/patterns/lessons لكل يوم موجود في الذاكرة.")


if __name__ == "__main__":
    main()
