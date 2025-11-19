#!/usr/bin/env python3
"""
Temporal Memory Engine – Hyper Factory
- تسجيل أحداث زمنية في ملف JSON (بدون لمس SQLite)
"""

import json
from pathlib import Path
from datetime import datetime

BASE = Path(__file__).resolve().parents[2]
TEMPORAL_DIR = BASE / "ai" / "memory" / "temporal"
TIMELINE_PATH = TEMPORAL_DIR / "timeline.json"


def load_timeline():
    if not TIMELINE_PATH.exists():
        return []
    try:
        with TIMELINE_PATH.open("r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, list):
                return data
            return []
    except Exception:
        return []


def save_timeline(events):
    TEMPORAL_DIR.mkdir(parents=True, exist_ok=True)
    with TIMELINE_PATH.open("w", encoding="utf-8") as f:
        json.dump(events, f, ensure_ascii=False, indent=2)


def record_event(event_type: str, details: dict):
    events = load_timeline()
    ev = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "event_type": event_type,
        "details": details,
    }
    events.append(ev)
    save_timeline(events)
    return ev, len(events)


def main():
    print("🕒 Temporal Memory Engine – تسجيل حدث زمني (heartbeat)")
    ev, total = record_event(
        "heartbeat",
        {
            "source": "temporal_memory_agent",
            "message": "دورة جديدة من محرك الذاكرة الزمنية.",
        },
    )
    print("✅ تم تسجيل حدث:")
    print(f"   - timestamp: {ev['timestamp']}")
    print(f"   - نوع الحدث: {ev['event_type']}")
    print(f"   - المسار   : {TIMELINE_PATH}")
    print(f"   - إجمالي الأحداث المسجَّلة: {total}")


if __name__ == "__main__":
    main()
