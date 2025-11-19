#!/usr/bin/env python3
"""
tools/hf_log_run_to_memory.py

الوظيفة:
- يقرأ آخر سطر من reports/basic_runs.log
- يحلله إلى:
  - وقت التشغيل
  - حالة كل عامل (ingestor/processor/analyzer/reporter)
  - success/fail للدورة
- يضيف حدث جديد في ai/memory/messages.jsonl
- يحدّث مؤشرات الجودة في ai/memory/quality.json
"""

import os
import sys
import json
from datetime import datetime
from typing import Dict, Any

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORTS_DIR = os.path.join(ROOT, "reports")
LOG_PATH = os.path.join(REPORTS_DIR, "basic_runs.log")

AI_DIR = os.path.join(ROOT, "ai")
MEMORY_DIR = os.path.join(AI_DIR, "memory")
MESSAGES_PATH = os.path.join(MEMORY_DIR, "messages.jsonl")
QUALITY_PATH = os.path.join(MEMORY_DIR, "quality.json")


def load_last_log_line(path: str) -> str:
    if not os.path.exists(path):
        print(f"❌ basic_runs.log غير موجود: {path}")
        sys.exit(1)

    last_line = ""
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()
            if stripped:
                last_line = stripped

    if not last_line:
        print("ℹ️ basic_runs.log موجود لكن لا يحتوي على أسطر فعّالة.")
        sys.exit(0)

    return last_line


def parse_log_line(line: str) -> Dict[str, Any]:
    """
    مثال السطر:
    2025-11-19 04:07:20 | ingestor_basic=OK | processor_basic=OK | analyzer_basic=OK | reporter_basic=OK
    """
    parts = [p.strip() for p in line.split("|")]
    if not parts:
        raise ValueError(f"لا يمكن تحليل السطر: {line!r}")

    ts_str = parts[0]
    steps_raw = parts[1:]

    # تحويل الوقت إلى ISO
    try:
        dt = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S")
        ts_iso = dt.isoformat() + "Z"
    except Exception:
        # fallback: نستخدم النص كما هو
        ts_iso = ts_str

    steps_status: Dict[str, str] = {}
    for part in steps_raw:
        if "=" in part:
            name, status = [x.strip() for x in part.split("=", 1)]
            if name:
                steps_status[name] = status

    success = all(v == "OK" for v in steps_status.values()) if steps_status else False

    return {
        "timestamp": ts_iso,
        "pipeline": "basic",
        "steps": steps_status,
        "success": success,
        "raw_line": line,
    }


def ensure_memory_dir():
    os.makedirs(MEMORY_DIR, exist_ok=True)
    # التأكد من وجود الملفات الأساسية
    if not os.path.exists(MESSAGES_PATH):
        with open(MESSAGES_PATH, "w", encoding="utf-8") as f:
            f.write("")
    if not os.path.exists(QUALITY_PATH):
        with open(QUALITY_PATH, "w", encoding="utf-8") as f:
            json.dump(
                {
                    "total_runs": 0,
                    "success_runs": 0,
                    "failed_runs": 0,
                    "last_run_at": None,
                    "last_status": {},
                    "notes": "Hyper Factory quality baseline. This file is updated by tools/hf_log_run_to_memory.py",
                },
                f,
                ensure_ascii=False,
                indent=2,
            )


def append_message(event: Dict[str, Any]):
    with open(MESSAGES_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")


def update_quality(event: Dict[str, Any]):
    if os.path.exists(QUALITY_PATH):
        try:
            with open(QUALITY_PATH, "r", encoding="utf-8") as f:
                quality = json.load(f)
        except Exception:
            quality = {}
    else:
        quality = {}

    total_runs = int(quality.get("total_runs", 0)) + 1
    success_runs = int(quality.get("success_runs", 0))
    failed_runs = int(quality.get("failed_runs", 0))

    if event.get("success"):
        success_runs += 1
    else:
        failed_runs += 1

    quality.update(
        {
            "total_runs": total_runs,
            "success_runs": success_runs,
            "failed_runs": failed_runs,
            "last_run_at": event.get("timestamp"),
            "last_status": event.get("steps", {}),
        }
    )

    with open(QUALITY_PATH, "w", encoding="utf-8") as f:
        json.dump(quality, f, ensure_ascii=False, indent=2)

    return quality


def main():
    print("📂 ROOT         :", ROOT)
    print("📄 LOG_PATH     :", LOG_PATH)
    print("📂 MEMORY_DIR   :", MEMORY_DIR)
    print("----------------------------------------")

    ensure_memory_dir()
    line = load_last_log_line(LOG_PATH)
    print(f"ℹ️ آخر سطر في basic_runs.log:\n   {line}")

    event = parse_log_line(line)
    append_message(event)
    quality = update_quality(event)

    print("\n✅ تم تسجيل الحدث في ai/memory/messages.jsonl")
    print("📊 تحديث quality.json:")
    print(f"   - total_runs   : {quality['total_runs']}")
    print(f"   - success_runs : {quality['success_runs']}")
    print(f"   - failed_runs  : {quality['failed_runs']}")
    print(f"   - last_run_at  : {quality['last_run_at']}")
    print(f"   - last_status  : {quality['last_status']}")


if __name__ == "__main__":
    main()
