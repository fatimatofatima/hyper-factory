#!/usr/bin/env python3
"""
tools/hf_build_insights.py

يبني ملف ai/memory/insights.json من:
- ai/memory/quality.json
- ai/memory/messages.jsonl

المخرجات تشمل:
- success_rate
- success_streak
- failure_streak
- last_failure_at
- last_failure_steps
- last_runs (آخر N رنات)
"""

import os
import sys
import json
from datetime import datetime
from typing import List, Dict, Any

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEMORY_DIR = os.path.join(ROOT, "ai", "memory")
QUALITY_PATH = os.path.join(MEMORY_DIR, "quality.json")
MESSAGES_PATH = os.path.join(MEMORY_DIR, "messages.jsonl")
INSIGHTS_PATH = os.path.join(MEMORY_DIR, "insights.json")

LAST_N = 10  # عدد آخر الرنات في التقرير


def load_json(path: str, default):
    if not os.path.exists(path):
        return default
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default


def load_messages(path: str) -> List[Dict[str, Any]]:
    if not os.path.exists(path):
        return []
    events: List[Dict[str, Any]] = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                ev = json.loads(line)
                events.append(ev)
            except Exception:
                # نتجاهل الأسطر المعطوبة
                continue
    return events


def parse_timestamp(ts_str: str):
    if not ts_str:
        return None
    # نحاول ISO أولاً
    try:
        return datetime.fromisoformat(ts_str.replace("Z", ""))
    except Exception:
        # fallback: نعيد None
        return None


def build_insights():
    quality = load_json(
        QUALITY_PATH,
        {
            "total_runs": 0,
            "success_runs": 0,
            "failed_runs": 0,
            "last_run_at": None,
            "last_status": {},
        },
    )
    events = load_messages(MESSAGES_PATH)

    total_runs = int(quality.get("total_runs", 0))
    success_runs = int(quality.get("success_runs", 0))
    failed_runs = int(quality.get("failed_runs", 0))

    success_rate = 0.0
    if total_runs > 0:
        success_rate = (success_runs / total_runs) * 100.0

    # ترتيب الأحداث زمنيًا حسب timestamp (لو متاح)
    def sort_key(ev: Dict[str, Any]):
        dt = parse_timestamp(ev.get("timestamp") or "")
        return dt or datetime.min

    events_sorted = sorted(events, key=sort_key)

    # حساب الستريك الحالي من آخر حدث إلى الخلف
    success_streak = 0
    failure_streak = 0
    last_failure_at = None
    last_failure_steps: Dict[str, Any] = {}

    for ev in reversed(events_sorted):
        if ev.get("success"):
            if failure_streak > 0:
                # كان فيه ستريك فشل وانتهى
                break
            success_streak += 1
        else:
            if success_streak > 0:
                # كان فيه ستريك نجاح وانتهى
                break
            failure_streak += 1

    # آخر فشل
    for ev in reversed(events_sorted):
        if not ev.get("success"):
            last_failure_at = ev.get("timestamp")
            last_failure_steps = ev.get("steps", {})
            break

    # آخر N رنات
    last_runs = list(reversed(events_sorted))[:LAST_N]

    insights = {
        "total_runs": total_runs,
        "success_runs": success_runs,
        "failed_runs": failed_runs,
        "success_rate": round(success_rate, 2),
        "success_streak": success_streak,
        "failure_streak": failure_streak,
        "last_failure_at": last_failure_at,
        "last_failure_steps": last_failure_steps,
        "last_runs_count": len(last_runs),
        "last_runs": last_runs,
        "generated_at": datetime.utcnow().isoformat() + "Z",
    }

    os.makedirs(MEMORY_DIR, exist_ok=True)
    with open(INSIGHTS_PATH, "w", encoding="utf-8") as f:
        json.dump(insights, f, ensure_ascii=False, indent=2)

    return insights


def main():
    print("📂 ROOT        :", ROOT)
    print("📂 MEMORY_DIR  :", MEMORY_DIR)
    print("📄 QUALITY     :", QUALITY_PATH)
    print("📄 MESSAGES    :", MESSAGES_PATH)
    print("📄 INSIGHTS    :", INSIGHTS_PATH)
    print("----------------------------------------")

    insights = build_insights()

    print("✅ تم بناء insights:")
    print(f"   - total_runs     : {insights['total_runs']}")
    print(f"   - success_runs   : {insights['success_runs']}")
    print(f"   - failed_runs    : {insights['failed_runs']}")
    print(f"   - success_rate   : {insights['success_rate']}%")
    print(f"   - success_streak : {insights['success_streak']}")
    print(f"   - failure_streak : {insights['failure_streak']}")
    print(f"   - last_failure_at: {insights['last_failure_at']}")


if __name__ == "__main__":
    main()
