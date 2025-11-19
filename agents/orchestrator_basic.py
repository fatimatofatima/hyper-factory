#!/usr/bin/env python3
# orchestrator_basic.py
# عامل تنسيق بسيط:
# - يشغّل ingestor_basic ثم processor_basic
# - يكتب سطر تقرير في reports/basic_runs.log

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


def run_step(name, script_path):
    print(f"\n================= 🚀 تشغيل {name} =================")
    if not os.path.exists(script_path):
        print(f"❌ الملف غير موجود: {script_path}")
        return False

    try:
        result = subprocess.run(
            [script_path],
            cwd=ROOT,
            stdout=sys.stdout,
            stderr=sys.stderr,
            check=False,
        )
        if result.returncode == 0:
            print(f"✅ {name} انتهى بنجاح (code=0)")
            return True
        else:
            print(f"❌ {name} انتهى بخطأ (code={result.returncode})")
            return False
    except Exception as e:
        print(f"❌ استثناء أثناء تشغيل {name}: {e}")
        return False


def append_report(status_ingestor, status_processor):
    os.makedirs(REPORTS_DIR, exist_ok=True)
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    line = (
        f"{now} | "
        f"ingestor_basic={'OK' if status_ingestor else 'FAIL'} | "
        f"processor_basic={'OK' if status_processor else 'FAIL'}\n"
    )

    try:
        with open(LOG_PATH, "a", encoding="utf-8") as f:
            f.write(line)
        print(f"\n📝 تم تسجيل الدورة في: {LOG_PATH}")
    except Exception as e:
        print(f"⚠️ تعذر كتابة تقرير في {LOG_PATH}: {e}")


def main():
    print("📁 ROOT         :", ROOT)
    print("📂 AGENTS_DIR   :", AGENTS_DIR)
    print("📝 REPORTS_DIR  :", REPORTS_DIR)
    print("----------------------------------------")

    ok_ingestor = run_step("ingestor_basic", INGESTOR_SH)
    ok_processor = run_step("processor_basic", PROCESSOR_SH)

    append_report(ok_ingestor, ok_processor)

    if ok_ingestor and ok_processor:
        print("\n✅ الدورة الأساسية (ingestor + processor) انتهت بنجاح.")
        sys.exit(0)
    else:
        print("\n⚠️ الدورة انتهت مع أخطاء في واحد أو أكثر من الخطوات.")
        sys.exit(1)


if __name__ == "__main__":
    main()
