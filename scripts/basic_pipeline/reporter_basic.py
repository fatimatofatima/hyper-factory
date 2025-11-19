#!/usr/bin/env python3
"""
reporter_basic.py
تقرير بسيط لأداء دورة Hyper Factory الأساسية.

المدخلات:
- reports/basic_runs.log  (سطر لكل دورة)

المخرجات:
- data/report/summary_basic.json
- data/report/summary_basic.txt
"""

import json
from pathlib import Path
from datetime import datetime

# ROOT = /root/hyper-factory (يُستنتج من مكان السكربت)
ROOT = Path(__file__).resolve().parents[2]
REPORTS_DIR = ROOT / "reports"
LOG_PATH = REPORTS_DIR / "basic_runs.log"

DATA_REPORT_DIR = ROOT / "data" / "report"
SUMMARY_JSON = DATA_REPORT_DIR / "summary_basic.json"
SUMMARY_TXT = DATA_REPORT_DIR / "summary_basic.txt"


def parse_log_line(line: str):
    """
    مثال سطر:
    2025-11-19 03:24:41 | ingestor_basic=OK | processor_basic=OK
    """
    line = line.strip()
    if not line:
        return None

    parts = [p.strip() for p in line.split("|")]
    if not parts:
        return None

    ts_str = parts[0]
    try:
        ts = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S")
    except ValueError:
        # لو الفرمات اختلف، نخزن السلسلة كـ string فقط
        ts = ts_str

    statuses = {}
    for token in parts[1:]:
        if "=" in token:
            k, v = token.split("=", 1)
            statuses[k.strip()] = v.strip()

    return {
        "timestamp": ts_str,
        "parsed_timestamp": ts if isinstance(ts, datetime) else None,
        "statuses": statuses,
    }


def load_runs():
    if not LOG_PATH.exists():
        return []

    runs = []
    with LOG_PATH.open("r", encoding="utf-8") as f:
        for line in f:
            parsed = parse_log_line(line)
            if parsed:
                runs.append(parsed)
    return runs


def build_summary(runs):
    total = len(runs)
    success = 0
    failure = 0

    last_run = runs[-1] if runs else None

    for r in runs:
        statuses = r["statuses"]
        # نعتبر الـ run ناجح لو كل القيم = "OK"
        if statuses and all(v.upper() == "OK" for v in statuses.values()):
            success += 1
        else:
            failure += 1

    summary = {
        "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "log_path": str(LOG_PATH),
        "total_runs": total,
        "success_runs": success,
        "failed_runs": failure,
    }

    if last_run:
        summary["last_run_at"] = last_run["timestamp"]
        summary["last_statuses"] = last_run["statuses"]
    else:
        summary["last_run_at"] = None
        summary["last_statuses"] = {}

    return summary


def write_outputs(summary):
    DATA_REPORT_DIR.mkdir(parents=True, exist_ok=True)

    # JSON
    with SUMMARY_JSON.open("w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)

    # TXT
    lines = [
        "===== Hyper Factory Basic Summary =====",
        f"Generated at   : {summary['generated_at']}",
        f"Log file       : {summary['log_path']}",
        "",
        f"Total runs     : {summary['total_runs']}",
        f"Success runs   : {summary['success_runs']}",
        f"Failed runs    : {summary['failed_runs']}",
        "",
        f"Last run at    : {summary['last_run_at']}",
        f"Last statuses  : {summary['last_statuses']}",
        "",
    ]
    with SUMMARY_TXT.open("w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main():
    print(f"📂 ROOT          : {ROOT}")
    print(f"📂 REPORTS_DIR   : {REPORTS_DIR}")
    print(f"📄 LOG_PATH      : {LOG_PATH}")
    print(f"📂 DATA_REPORT   : {DATA_REPORT_DIR}")
    print("----------------------------------------")

    runs = load_runs()
    if not runs:
        print("ℹ️ لا توجد أي دورات مسجّلة في basic_runs.log حتى الآن.")
    else:
        print(f"ℹ️ عدد الدورات المقروءة من اللوج: {len(runs)}")

    summary = build_summary(runs)
    write_outputs(summary)

    print("✅ تم توليد:")
    print(f"   - {SUMMARY_JSON}")
    print(f"   - {SUMMARY_TXT}")


if __name__ == "__main__":
    main()
