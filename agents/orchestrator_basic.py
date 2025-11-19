#!/usr/bin/env python3
# orchestrator_basic.py
# يشغّل سلسلة العمال:
# ingestor_basic -> processor_basic -> analyzer_basic -> reporter_basic
# ويسجّل النتيجة في reports/basic_runs.log

import os
import sys
import subprocess
from datetime import datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AGENTS_DIR = os.path.join(ROOT, "agents")
REPORTS_DIR = os.path.join(ROOT, "reports")
LOG_PATH = os.path.join(REPORTS_DIR, "basic_runs.log")

INGESTOR_SH = os.path.join(AGENTS_DIR, "ingestor_basic.sh")
PROCESSOR_SH = os.path.join(AGENTS_DIR, "processor_basic.sh")
ANALYZER_SH = os.path.join(AGENTS_DIR, "analyzer_basic.sh")
REPORTER_SH = os.path.join(AGENTS_DIR, "reporter_basic.sh")


def run_step(name: str, script_path: str) -> bool:
    print(f"\n================= 🚀 تشغيل {name} =================")
    print(f"📄 SCRIPT : {script_path}")

    if not os.path.exists(script_path):
        print(f"❌ الملف غير موجود: {script_path}")
        return False

    if not os.access(script_path, os.X_OK):
        print(f"ℹ️ جعل السكربت قابلاً للتنفيذ: {script_path}")
        try:
            os.chmod(script_path, 0o755)
        except Exception as e:
            print(f"❌ لا يمكن ضبط صلاحيات التنفيذ: {e}")
            return False

    try:
        subprocess.run([script_path], check=True)
        print(f"✅ {name} انتهى بنجاح.")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {name} فشل (exit code={e.returncode})")
        return False
    except Exception as e:
        print(f"❌ خطأ أثناء تشغيل {name}: {e}")
        return False


def main():
    os.makedirs(REPORTS_DIR, exist_ok=True)

    print("📁 ROOT         :", ROOT)
    print("📂 AGENTS_DIR   :", AGENTS_DIR)
    print("📝 REPORTS_DIR  :", REPORTS_DIR)
    print("----------------------------------------")

    statuses = {}

    statuses["ingestor_basic"] = "OK" if run_step("ingestor_basic", INGESTOR_SH) else "FAIL"
    statuses["processor_basic"] = "OK" if run_step("processor_basic", PROCESSOR_SH) else "FAIL"
    statuses["analyzer_basic"] = "OK" if run_step("analyzer_basic", ANALYZER_SH) else "FAIL"
    statuses["reporter_basic"] = "OK" if run_step("reporter_basic", REPORTER_SH) else "FAIL"

    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    status_str = " | ".join(f"{k}={v}" for k, v in statuses.items())

    line = f"{ts} | {status_str}\n"
    try:
        with open(LOG_PATH, "a", encoding="utf-8") as f:
            f.write(line)
        print(f"\n📝 تم تسجيل الدورة في: {LOG_PATH}")
    except Exception as e:
        print(f"❌ خطأ في كتابة basic_runs.log: {e}")

    print("\n================= ✅ ملخص الدورة =================")
    print(f"الوقت        : {ts}")
    for k, v in statuses.items():
        print(f"- {k:15s}: {v}")

    if all(v == "OK" for v in statuses.values()):
        print("\n✅ الدورة الأساسية (ingestor + processor + analyzer + reporter) انتهت بنجاح.")
    else:
        print("\n⚠️ الدورة انتهت مع بعض الإخفاقات. راجع الرسائل أعلاه.")


if __name__ == "__main__":
    main()
