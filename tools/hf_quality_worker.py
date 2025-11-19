#!/usr/bin/env python3
"""
tools/hf_quality_worker.py

عامل جودة:
- يقرأ ai/memory/quality.json
- يصنف الحالة: GREEN / YELLOW / RED / EMPTY
- يستخرج أكثر العمال مشكلةً
- يكتب:
  - ai/memory/quality_status.json
  - ai/memory/quality_report.txt
"""

import os
import json
from datetime import datetime
from typing import Dict, Any, List

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEMORY_DIR = os.path.join(ROOT, "ai", "memory")
QUALITY_JSON = os.path.join(MEMORY_DIR, "quality.json")
STATUS_JSON = os.path.join(MEMORY_DIR, "quality_status.json")
REPORT_TXT = os.path.join(MEMORY_DIR, "quality_report.txt")


def load_quality() -> Dict[str, Any]:
    if not os.path.exists(QUALITY_JSON):
        print(f"❌ لا يوجد quality.json بعد: {QUALITY_JSON}")
        return {}

    with open(QUALITY_JSON, "r", encoding="utf-8") as f:
        try:
            return json.load(f)
        except Exception as e:
            print(f"❌ فشل تحميل quality.json: {e}")
            return {}


def classify_status(q: Dict[str, Any]) -> Dict[str, Any]:
    total = q.get("total_runs", 0) or 0
    success_runs = q.get("success_runs", 0) or 0
    failed_runs = q.get("failed_runs", 0) or 0
    success_rate = q.get("success_rate", 0.0) or 0.0
    steps = q.get("steps", {}) or {}

    if total == 0:
        overall = "EMPTY"
        risk = "UNKNOWN"
    else:
        if success_rate >= 0.95 and all(
            (s.get("ok_rate", 0.0) or 0.0) >= 0.95 for s in steps.values()
        ):
            overall = "GREEN"
            risk = "LOW"
        elif success_rate >= 0.80:
            overall = "YELLOW"
            risk = "MEDIUM"
        else:
            overall = "RED"
            risk = "HIGH"

    # ترتيب العمال حسب معدل الفشل
    step_list: List[Dict[str, Any]] = []
    for name, s in steps.items():
        step_list.append(
            {
                "name": name,
                "count": s.get("count", 0),
                "ok": s.get("ok", 0),
                "fail": s.get("fail", 0),
                "ok_rate": s.get("ok_rate", 0.0),
                "fail_rate": s.get("fail_rate", 0.0),
            }
        )

    step_list_sorted = sorted(
        step_list,
        key=lambda x: (x["fail_rate"], x["fail"], -x["ok_rate"]),
        reverse=True,
    )

    top_problems = [s for s in step_list_sorted if s["fail"] > 0][:5]

    summary_text = f"Status={overall}, risk={risk}, success_rate={success_rate:.2%}, total_runs={total}, failed_runs={failed_runs}"

    return {
        "overall_status": overall,
        "risk_level": risk,
        "summary": summary_text,
        "total_runs": total,
        "success_runs": success_runs,
        "failed_runs": failed_runs,
        "success_rate": success_rate,
        "steps_ranked": step_list_sorted,
        "top_problems": top_problems,
    }


def write_status(status: Dict[str, Any]) -> None:
    os.makedirs(MEMORY_DIR, exist_ok=True)
    now_iso = datetime.utcnow().isoformat() + "Z"
    payload = {
        "generated_at": now_iso,
        "status": status,
    }

    with open(STATUS_JSON, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    lines: List[str] = []
    lines.append("===== Hyper Factory Quality Report =====")
    lines.append(f"Generated at : {now_iso}")
    lines.append("")
    lines.append(f"Overall      : {status['overall_status']}")
    lines.append(f"Risk level   : {status['risk_level']}")
    lines.append(f"Success rate : {status['success_rate']:.2%}")
    lines.append(f"Total runs   : {status['total_runs']}")
    lines.append(f"Failed runs  : {status['failed_runs']}")
    lines.append("")
    lines.append("----- Top Problematic Steps -----")
    if not status["top_problems"]:
        lines.append("- لا توجد خطوات بها فشل مسجّل حالياً.")
    else:
        for s in status["top_problems"]:
            lines.append(
                f"- {s['name']}: fail={s['fail']}, count={s['count']}, fail_rate={s['fail_rate']:.2%}, ok_rate={s['ok_rate']:.2%}"
            )

    with open(REPORT_TXT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print("✅ تم توليد تقرير الجودة:")
    print(f"   - {STATUS_JSON}")
    print(f"   - {REPORT_TXT}")


def main():
    print("📂 MEMORY_DIR :", MEMORY_DIR)
    print("📄 QUALITY    :", QUALITY_JSON)
    print("----------------------------------------")

    q = load_quality()
    if not q:
        print("ℹ️ لا توجد بيانات جودة لبنائها حتى الآن.")
        return

    status = classify_status(q)
    write_status(status)


if __name__ == "__main__":
    main()
