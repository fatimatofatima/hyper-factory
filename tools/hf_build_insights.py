#!/usr/bin/env python3
"""
tools/hf_build_insights.py

يبني طبقة insights من ذاكرة Hyper Factory:
- يقرأ ai/memory/messages.jsonl
- يكتب:
  - ai/memory/insights.json
  - ai/memory/insights.txt
"""

import os
import sys
import json
from datetime import datetime
from typing import List, Dict, Any

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEMORY_DIR = os.path.join(ROOT, "ai", "memory")
MESSAGES_PATH = os.path.join(MEMORY_DIR, "messages.jsonl")
INSIGHTS_JSON = os.path.join(MEMORY_DIR, "insights.json")
INSIGHTS_TXT = os.path.join(MEMORY_DIR, "insights.txt")


def load_events() -> List[Dict[str, Any]]:
    if not os.path.exists(MESSAGES_PATH):
        print(f"ℹ️ لا يوجد ملف events بعد: {MESSAGES_PATH}")
        return []

    events: List[Dict[str, Any]] = []
    with open(MESSAGES_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
                events.append(obj)
            except Exception as e:
                print(f"⚠️ تعذّر قراءة سطر من messages.jsonl: {e}")
    return events


def build_step_stats(events: List[Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
    stats: Dict[str, Dict[str, Any]] = {}

    for ev in events:
        steps = ev.get("steps", {}) or {}
        for name, status in steps.items():
            name = str(name)
            status_up = str(status).upper()

            if name not in stats:
                stats[name] = {
                    "count": 0,
                    "ok": 0,
                    "fail": 0,
                }

            stats[name]["count"] += 1
            if status_up == "OK":
                stats[name]["ok"] += 1
            else:
                stats[name]["fail"] += 1

    # إضافة نسب النجاح/الفشل لكل عامل
    for name, s in stats.items():
        c = s["count"] or 1
        ok_rate = s["ok"] / c
        fail_rate = s["fail"] / c
        s["ok_rate"] = ok_rate
        s["fail_rate"] = fail_rate

    return stats


def build_recent_window(events: List[Dict[str, Any]], window: int = 20) -> List[Dict[str, Any]]:
    sub = events[-window:] if len(events) > window else events[:]
    # نعيد فقط حقول مختصرة
    recent: List[Dict[str, Any]] = []
    for ev in sub:
        recent.append(
            {
                "timestamp": ev.get("timestamp"),
                "success": ev.get("success"),
                "steps": ev.get("steps", {}),
            }
        )
    return recent


def main():
    print("📂 ROOT       :", ROOT)
    print("📂 MEMORY_DIR :", MEMORY_DIR)
    print("📄 MESSAGES   :", MESSAGES_PATH)
    print("📄 INSIGHTS   :", INSIGHTS_JSON)
    print("----------------------------------------")

    os.makedirs(MEMORY_DIR, exist_ok=True)

    events = load_events()
    total_runs = len(events)
    success_runs = sum(1 for e in events if e.get("success"))
    failed_runs = total_runs - success_runs

    if total_runs == 0:
        print("ℹ️ لا توجد أحداث في الذاكرة حتى الآن. سيتم إنشاء ملف insights فارغ.")
        insights = {
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "total_runs": 0,
            "success_runs": 0,
            "failed_runs": 0,
            "success_rate": 0.0,
            "last_run_at": None,
            "last_status": {},
            "steps": {},
            "recent_window_size": 0,
            "recent_runs": [],
        }
    else:
        success_rate = success_runs / total_runs
        last_event = events[-1]
        last_run_at = last_event.get("timestamp")
        last_status = last_event.get("steps", {})

        step_stats = build_step_stats(events)
        recent = build_recent_window(events, window=20)

        insights = {
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "total_runs": total_runs,
            "success_runs": success_runs,
            "failed_runs": failed_runs,
            "success_rate": success_rate,
            "last_run_at": last_run_at,
            "last_status": last_status,
            "steps": step_stats,
            "recent_window_size": len(recent),
            "recent_runs": recent,
        }

    # كتابة insights.json
    with open(INSIGHTS_JSON, "w", encoding="utf-8") as f:
        json.dump(insights, f, ensure_ascii=False, indent=2)

    # كتابة insights.txt (نص مبسط)
    lines: List[str] = []
    lines.append("===== Hyper Factory Memory Insights =====")
    lines.append(f"Generated at : {insights['generated_at']}")
    lines.append("")
    lines.append(f"Total runs   : {insights['total_runs']}")
    lines.append(f"Success runs : {insights['success_runs']}")
    lines.append(f"Failed runs  : {insights['failed_runs']}")
    lines.append(f"Success rate : {insights['success_rate']:.2%}")
    lines.append("")
    lines.append(f"Last run at  : {insights['last_run_at']}")
    lines.append(f"Last status  : {insights['last_status']}")
    lines.append("")
    lines.append("----- Per-step stats -----")
    for name, s in insights["steps"].items():
        lines.append(
            f"- {name}: count={s['count']}, ok={s['ok']}, fail={s['fail']}, ok_rate={s['ok_rate']:.2%}"
        )

    lines.append("")
    lines.append(f"----- Recent {insights['recent_window_size']} runs -----")
    for ev in insights["recent_runs"]:
        lines.append(
            f"{ev.get('timestamp')} | success={ev.get('success')} | steps={ev.get('steps')}"
        )

    with open(INSIGHTS_TXT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print("----------------------------------------")
    print("✅ تم بناء insights من الذاكرة:")
    print(f"   - {INSIGHTS_JSON}")
    print(f"   - {INSIGHTS_TXT}")


if __name__ == "__main__":
    main()
