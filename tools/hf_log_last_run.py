#!/usr/bin/env python3
"""
tools/hf_log_last_run.py

يسجّل آخر دورة من reports/basic_runs.log في:
- ai/memory/messages.jsonl
- ai/memory/quality.json
"""

import os
import sys
import json
from datetime import datetime
from typing import Dict, Any, Tuple

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORTS_DIR = os.path.join(ROOT, "reports")
LOG_PATH = os.path.join(REPORTS_DIR, "basic_runs.log")

MEMORY_DIR = os.path.join(ROOT, "ai", "memory")
MESSAGES_PATH = os.path.join(MEMORY_DIR, "messages.jsonl")
QUALITY_PATH = os.path.join(MEMORY_DIR, "quality.json")


def load_quality() -> Dict[str, Any]:
    if not os.path.exists(QUALITY_PATH):
        return {
            "total_runs": 0,
            "success_runs": 0,
            "failed_runs": 0,
            "last_run_at": None,
            "last_status": {},
        }
    try:
        with open(QUALITY_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {
            "total_runs": 0,
            "success_runs": 0,
            "failed_runs": 0,
            "last_run_at": None,
            "last_status": {},
        }


def parse_run_line(line: str) -> Tuple[str, Dict[str, str], bool]:
    """
    مثال سطر:
    2025-11-19 04:07:20 | ingestor_basic=OK | processor_basic=OK | analyzer_basic=OK | reporter_basic=OK
    """
    parts = [p.strip() for p in line.strip().split("|") if p.strip()]
    if not parts:
        raise ValueError("سطر فارغ في basic_runs.log")

    ts_str = parts[0]  # "YYYY-MM-DD HH:MM:SS"
    steps: Dict[str, str] = {}

    for p in parts[1:]:
        if "=" in p:
            name, status = p.split("=", 1)
            steps[name.strip()] = status.strip()

    success = bool(steps) and all(v.upper() == "OK" for v in steps.values())
    return ts_str, steps, success


def convert_to_iso(ts_str: str) -> str:
    """
    يحوّل "YYYY-MM-DD HH:MM:SS" إلى ISO (UTC) مع Z.
    """
    try:
        dt = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S")
        return dt.isoformat() + "Z"
    except Exception:
        # لو فشل نعيد النص كما هو
        return ts_str


def read_last_log_line(path: str) -> str:
    if not os.path.exists(path):
        raise FileNotFoundError(f"basic_runs.log غير موجود: {path}")

    last = None
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                last = line
    if not last:
        raise ValueError("basic_runs.log لا يحتوي على أسطر فعّالة.")
    return last


def main():
    print("📂 ROOT       :", ROOT)
    print("📂 REPORTS    :", REPORTS_DIR)
    print("📄 LOG_PATH   :", LOG_PATH)
    print("📂 MEMORY_DIR :", MEMORY_DIR)
    print("----------------------------------------")

    try:
        last_line = read_last_log_line(LOG_PATH)
    except Exception as e:
        print(f"❌ تعذّر قراءة آخر سطر من basic_runs.log: {e}")
        sys.exit(1)

    ts_str, steps, success = parse_run_line(last_line)
    ts_iso = convert_to_iso(ts_str)

    print(f"ℹ️ آخر سطر: {last_line}")
    print(f"   timestamp : {ts_str} -> {ts_iso}")
    print(f"   steps     : {steps}")
    print(f"   success   : {success}")

    os.makedirs(MEMORY_DIR, exist_ok=True)

    # 1) تحديث messages.jsonl
    event = {
        "timestamp": ts_iso,
        "success": success,
        "steps": steps,
        "raw_line": last_line,
    }
    with open(MESSAGES_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")

    # 2) تحديث quality.json
    quality = load_quality()
    quality["total_runs"] = int(quality.get("total_runs", 0)) + 1
    if success:
        quality["success_runs"] = int(quality.get("success_runs", 0)) + 1
    else:
        quality["failed_runs"] = int(quality.get("failed_runs", 0)) + 1

    quality["last_run_at"] = ts_iso
    quality["last_status"] = steps

    with open(QUALITY_PATH, "w", encoding="utf-8") as f:
        json.dump(quality, f, ensure_ascii=False, indent=2)

    print("----------------------------------------")
    print("✅ تم تسجيل آخر دورة في ai/memory:")
    print(f"   - messages.jsonl : {MESSAGES_PATH}")
    print(f"   - quality.json   : {QUALITY_PATH}")
    print(f"   - success        : {success}")


if __name__ == "__main__":
    main()
