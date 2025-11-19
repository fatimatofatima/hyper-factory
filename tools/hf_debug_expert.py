#!/usr/bin/env python3
"""
tools/hf_debug_expert.py

عامل Debug Expert:
- يقرأ reports/basic_runs.log
- يكتشف الدورات التي تحتوي على فشل في أي عامل (ingestor/processor/analyzer/reporter)
- يحلل نوع الفشل لكل عامل
- ينتج:
  - ai/memory/debug_cases.json  (تفصيلي)
  - ai/memory/debug_report.txt  (تقرير نصي مختصر)
"""

import os
import json
from datetime import datetime
from typing import Dict, Any, List

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORTS_DIR = os.path.join(ROOT, "reports")
LOG_PATH = os.path.join(REPORTS_DIR, "basic_runs.log")

MEMORY_DIR = os.path.join(ROOT, "ai", "memory")
DEBUG_JSON = os.path.join(MEMORY_DIR, "debug_cases.json")
DEBUG_TXT = os.path.join(MEMORY_DIR, "debug_report.txt")


def ensure_memory_dir() -> None:
    os.makedirs(MEMORY_DIR, exist_ok=True)


def classify_severity(status: str) -> str:
    s = status.upper()
    if any(k in s for k in ["ERROR", "FAIL", "FAILED", "EXCEPTION", "TRACEBACK"]):
        return "HIGH"
    if "MISSING" in s or "TIMEOUT" in s or "RETRY" in s:
        return "MEDIUM"
    return "LOW"


def build_suggestion(step: str, status: str) -> str:
    s = status.upper()
    step_name = step

    # قواعد بسيطة حسب اسم العامل
    if step_name == "ingestor_basic":
        if "MISSING" in s:
            return "تحقق من مسارات data/inbox و data/raw، وتأكد من وجود ملفات صالحة للقراءة."
        if "ERROR" in s or "FAIL" in s:
            return "راجع صلاحيات الملفات في data/raw وتحقق من لوج ingestor_basic لمزيد من التفاصيل."
        return "مراجعة مصادر الإدخال والتأكد من ثبات تنسيق البيانات."

    if step_name == "processor_basic":
        if "MISSING" in s:
            return "تحقق من وجود ملفات meta ومجلد data/processed، وأعد تشغيل processor_basic."
        if "ERROR" in s or "FAIL" in s:
            return "راجع منطق توليد meta في processor_basic.py وتأكد من التعامل مع جميع الحالات الشاذة."
        return "تحسين منطق المعالجة وتسجيل مزيد من اللوج عند الفشل."

    if step_name == "analyzer_basic":
        if "MISSING" in s:
            return "تأكد من وجود ملفات meta في data/processed قبل تشغيل analyzer_basic."
        if "ERROR" in s or "FAIL" in s:
            return "راجع معالجة JSON/نصوص meta في analyzer_basic.py وحدد السطر المسبب للخطأ."
        return "إضافة فحوصات صحة للمدخلات قبل بناء semantic."

    if step_name == "reporter_basic":
        if "MISSING" in s:
            return "تأكد من وجود ملفات semantic في data/semantic قبل تشغيل reporter_basic."
        if "ERROR" in s or "FAIL" in s:
            return "راجع منطق توليد التقارير في reporter_basic.py والمسارات data/serving و reports."
        return "تحسين رسائل الخطأ في reporter_basic وتسجيل مزيد من التفاصيل."

    # افتراضي
    if any(k in s for k in ["ERROR", "FAIL", "FAILED"]):
        return "راجع لوجات العامل وحدد الاستثناء المسجّل، ثم عالج السبب الجذري قبل إعادة التشغيل."
    if "MISSING" in s:
        return "تحقق من المسارات المطلوبة والملفات المفقودة وأعد تشغيل الدورة بعد التصحيح."
    return "مراجعة إعدادات هذا العامل والتحقق من التكوين قبل الاستمرار."


def parse_log_line(line: str) -> Dict[str, Any]:
    """
    مثال سطر:
    2025-11-19 04:07:20 | ingestor_basic=OK | processor_basic=OK | analyzer_basic=OK | reporter_basic=MISSING
    """
    line = line.strip()
    if not line:
        return {}

    parts = [p.strip() for p in line.split("|")]
    if not parts:
        return {}

    ts_str = parts[0]
    try:
        # نتوقع شكل: YYYY-MM-DD HH:MM:SS
        ts = datetime.strptime(ts_str, "%Y-%m-%d %H:%M:%S")
    except ValueError:
        # لو التنسيق مختلف، نخزن الخام فقط
        ts = None

    steps: Dict[str, str] = {}
    for chunk in parts[1:]:
        if "=" not in chunk:
            continue
        name, status = chunk.split("=", 1)
        steps[name.strip()] = status.strip()

    return {
        "timestamp_str": ts_str,
        "timestamp": ts.isoformat() if ts else None,
        "steps": steps,
        "raw_line": line,
    }


def analyze_log() -> Dict[str, Any]:
    if not os.path.exists(LOG_PATH):
        return {
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "total_runs": 0,
            "runs_with_failures": 0,
            "failed_steps": {},
            "cases": [],
            "note": f"basic_runs.log غير موجود: {LOG_PATH}",
        }

    cases: List[Dict[str, Any]] = []
    failed_steps_agg: Dict[str, int] = {}
    total_runs = 0
    runs_with_fail = 0

    with open(LOG_PATH, "r", encoding="utf-8") as f:
        for raw in f:
            parsed = parse_log_line(raw)
            if not parsed:
                continue

            total_runs += 1
            steps = parsed["steps"]
            run_failed = False

            for step, status in steps.items():
                if status.upper() != "OK":
                    run_failed = True
                    failed_steps_agg[step] = failed_steps_agg.get(step, 0) + 1
                    severity = classify_severity(status)
                    suggestion = build_suggestion(step, status)

                    cases.append(
                        {
                            "timestamp": parsed["timestamp"],
                            "timestamp_str": parsed["timestamp_str"],
                            "step": step,
                            "status": status,
                            "severity": severity,
                            "suggestion": suggestion,
                            "raw_line": parsed["raw_line"],
                        }
                    )

            if run_failed:
                runs_with_fail += 1

    return {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "total_runs": total_runs,
        "runs_with_failures": runs_with_fail,
        "failed_steps": failed_steps_agg,
        "cases": cases,
    }


def write_outputs(result: Dict[str, Any]) -> None:
    ensure_memory_dir()

    # JSON تفصيلي
    with open(DEBUG_JSON, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    lines: List[str] = []
    lines.append("===== Hyper Factory Debug Report =====")
    lines.append(f"Generated at : {result.get('generated_at')}")
    lines.append("")

    total_runs = result.get("total_runs", 0)
    runs_with_fail = result.get("runs_with_failures", 0)
    failed_steps = result.get("failed_steps", {})
    cases = result.get("cases", [])

    if total_runs == 0:
        lines.append("لا توجد دورات مسجلة في basic_runs.log بعد.")
    else:
        lines.append(f"Total runs         : {total_runs}")
        lines.append(f"Runs with failures : {runs_with_fail}")
        lines.append("")

        if runs_with_fail == 0:
            lines.append("✅ لا توجد دورات تحتوي على فشل في أي عامل حتى الآن.")
        else:
            lines.append("⚠️ تم رصد دورات بها فشل في واحد أو أكثر من العمال.")
            lines.append("")
            lines.append("----- Failed steps summary -----")
            if failed_steps:
                for step, cnt in failed_steps.items():
                    lines.append(f"- {step}: {cnt} failure(s)")
            else:
                lines.append("- (لا يوجد تفصيل للخطوات، راجع JSON مباشرة.)")

            lines.append("")
            lines.append("----- Debug cases (أول 10 حالات) -----")
            for case in cases[:10]:
                lines.append(f"* [{case.get('timestamp_str')}] step={case.get('step')} status={case.get('status')}")
                lines.append(f"  severity : {case.get('severity')}")
                lines.append(f"  suggestion: {case.get('suggestion')}")
                lines.append("")

    with open(DEBUG_TXT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


def main() -> None:
    print(f"📁 ROOT       : {ROOT}")
    print(f"📂 REPORTS    : {REPORTS_DIR}")
    print(f"📄 LOG_PATH   : {LOG_PATH}")
    print(f"📂 MEMORY_DIR : {MEMORY_DIR}")
    print("----------------------------------------")

    result = analyze_log()
    write_outputs(result)

    print("✅ تم توليد تقرير Debug Expert:")
    print(f"   - {DEBUG_JSON}")
    print(f"   - {DEBUG_TXT}")


if __name__ == "__main__":
    main()
