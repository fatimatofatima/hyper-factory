#!/usr/bin/env python3
# orchestrator_basic.py
# عامل تنسيق بسيط:
# - يشغّل بالترتيب:
#   1) ingestor_basic.sh
#   2) processor_basic.sh
#   3) analyzer_basic.sh
#   4) reporter_basic.sh
# - يسجّل نتيجة الدورة في reports/basic_runs.log

import os
import sys
import subprocess
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AGENTS_DIR = ROOT / "agents"
REPORTS_DIR = ROOT / "reports"
LOG_PATH = REPORTS_DIR / "basic_runs.log"

STEPS = [
    ("ingestor_basic", AGENTS_DIR / "ingestor_basic.sh"),
    ("processor_basic", AGENTS_DIR / "processor_basic.sh"),
    ("analyzer_basic", AGENTS_DIR / "analyzer_basic.sh"),
    ("reporter_basic", AGENTS_DIR / "reporter_basic.sh"),
]


def run_step(name: str, script_path: Path):
    print(f"\n================= 🚀 تشغيل {name} =================")
    print(f"📄 SCRIPT : {script_path}")

    if not script_path.exists():
        print(f"❌ الملف غير موجود: {script_path}")
        return "MISSING", 1

    if not os.access(str(script_path), os.X_OK):
        print(f"⚠️ الملف غير قابل للتنفيذ، سيتم التصحيح: {script_path}")
        try:
            os.chmod(script_path, 0o755)
        except Exception as e:
            print(f"❌ فشل chmod: {e}")
            return "NOT_EXECUTABLE", 1

    try:
        subprocess.run(
            [str(script_path)],
            check=True,
        )
        print(f"✅ {name} انتهى بنجاح.")
        return "OK", 0
    except subprocess.CalledProcessError as e:
        print(f"❌ فشل تشغيل {name} (exit code={e.returncode})")
        return "ERROR", e.returncode
    except Exception as e:
        print(f"❌ استثناء أثناء تشغيل {name}: {e}")
        return "ERROR", 1


def main():
    print("📁 ROOT         :", ROOT)
    print("📂 AGENTS_DIR   :", AGENTS_DIR)
    print("📝 REPORTS_DIR  :", REPORTS_DIR)
    print("----------------------------------------")

    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    statuses = {}
    overall_ok = True

    for name, script_path in STEPS:
        status, code = run_step(name, script_path)
        statuses[name] = status
        if status != "OK":
            overall_ok = False

    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    status_parts = [f"{k}={v}" for k, v in statuses.items()]
    line = f"{now} | " + " | ".join(status_parts)

    try:
        with LOG_PATH.open("a", encoding="utf-8") as log_f:
            log_f.write(line + "\n")
        print(f"\n📝 تم تسجيل الدورة في: {LOG_PATH}")
    except Exception as e:
        print(f"⚠️ تعذّر الكتابة في basic_runs.log: {e}")

    if overall_ok:
        print("\n✅ الدورة الأساسية (ingestor + processor + analyzer + reporter) انتهت بنجاح.")
        sys.exit(0)
    else:
        print("\n⚠️ الدورة انتهت مع أخطاء في واحد أو أكثر من الخطوات.")
        sys.exit(1)


if __name__ == "__main__":
    main()
