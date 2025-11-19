#!/usr/bin/env python3
"""
tools/hf_log_last_run.py

- يقرأ آخر سطر من reports/basic_runs.log
- يحوّله إلى حدث JSON
- يضيفه إلى ai/memory/messages.jsonl (مع تجنّب التكرار)
"""

import os
import sys
import json
from datetime import datetime
from typing import Dict, Any, Optional

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORTS_DIR = os.path.join(ROOT, "reports")
LOG_PATH = os.path.join(REPORTS_DIR, "basic_runs.log")

MEMORY_DIR = os.path.join(ROOT, "ai", "memory")
MESSAGES_PATH = os.path.join(MEMORY_DIR, "messages.jsonl")


def read_last_log_line() -> Optional[str]:
    if not os.path.exists(LOG_PATH):
        print(f"❌ لا يوجد basic_runs.log بعد: {LOG_PATH}")
        return None

    last_line = None
    with open(LOG_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                last_line = line

    if last_line is None:
        print(f"ℹ️ basic_runs.log موجود لكن فارغ: {LOG_PATH}")
        return None

    return last_line


def parse_log_line(line: str) -> Dict[str, Any]:
    parts = [p.strip() for p in line.split("|") if p.strip()]
    if not parts:
        raise ValueError("سطر فارغ أو غير متوقع")

    ts_str = parts[0]
    steps: Dict[str, str] = {}

    for token in parts[1:]:
        if "=" in token:
            name, status = token.split("=", 1)
            steps[name.strip()] = status.strip()

    success = bool(steps) and all(s.upper() == "OK" for s in steps.values())

    return {
        "timestamp": ts_str,
        "success": success,
        "steps": steps,
        "source": "basic_runs.log",
    }


def read_last_event() -> Optional[Dict[str, Any]]:
    if not os.path.exists(MESSAGES_PATH):
        return None

    last_line = None
    with open(MESSAGES_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                last_line = line
    if not last_line:
        return None

    try:
        return json.loads(last_line)
    except Exception:
        return None


def main():
    print("📂 ROOT       :", ROOT)
    print("📂 REPORTS    :", REPORTS_DIR)
    print("📄 LOG_PATH   :", LOG_PATH)
    print("📂 MEMORY_DIR :", MEMORY_DIR)
    print("📄 MESSAGES   :", MESSAGES_PATH)
    print("----------------------------------------")

    os.makedirs(MEMORY_DIR, exist_ok=True)

    line = read_last_log_line()
    if line is None:
        return

    event = parse_log_line(line)

    last_event = read_last_event()
    if last_event is not None:
        if (
            last_event.get("timestamp") == event["timestamp"]
            and last_event.get("steps") == event["steps"]
        ):
            print("ℹ️ آخر دورة مسجّلة في الذاكرة هي نفسها آخر سطر في اللوج، لن يتم التكرار.")
            return

    with open(MESSAGES_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")

    print("✅ تم تسجيل آخر دورة في الذاكرة:")
    print(f"   - timestamp: {event['timestamp']}")
    print(f"   - success  : {event['success']}")
    print(f"   - steps    : {event['steps']}")


if __name__ == "__main__":
    main()
