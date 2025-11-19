#!/usr/bin/env python3
"""
System Health Monitor

مراقب صحة النظام المتقدم:
- مراقبة الموارد (CPU, RAM, Disk)
- مراقبة حالة العوامل (agents)
- إعداد بيانات للصيانة التنبؤية (predictive maintenance)
"""

import os
import json
import shutil
import psutil  # يتطلب: pip install psutil
from datetime import datetime

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPORTS_DIR = os.path.join(ROOT_DIR, "reports")
os.makedirs(REPORTS_DIR, exist_ok=True)


def collect_resource_stats():
    disk = shutil.disk_usage("/")
    mem = psutil.virtual_memory()
    load1, load5, load15 = os.getloadavg()

    return {
        "timestamp": datetime.now().isoformat(),
        "cpu_load": {
            "load1": load1,
            "load5": load5,
            "load15": load15,
        },
        "memory": {
            "total": mem.total,
            "available": mem.available,
            "percent": mem.percent,
        },
        "disk": {
            "total": disk.total,
            "used": disk.used,
            "free": disk.free,
        },
    }


def main():
    stats = collect_resource_stats()
    out_path = os.path.join(REPORTS_DIR, "system_health_snapshot.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(stats, f, ensure_ascii=False, indent=2)

    print(f"✅ SystemHealthMonitor: snapshot written to {out_path}")


if __name__ == "__main__":
    main()
