#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
hf_fix_agents_data.py
إصلاح بيانات الـ Agents في ai/memory/people/agents_levels.json

- يحل مشكلة:
  * agent = 0,1,2,3
  * display_name = 0,1,2,3
  * level = "missing"

- يكتب ملف JSON نظيف بصيغة قائمة من الكائنات:
  [
    {
      "agent": "analyzer_basic",
      "family": "pipeline",
      "display_name": "عامل التحليل الدلالي",
      "role": "data_analyzer",
      "level": "expert",
      "salary_index": 1.8,
      "total_runs": 16,
      "success_runs": 16,
      "failed_runs": 0,
      "success_rate": 1.0
    },
    ...
  ]
"""

import json
from pathlib import Path

AGENTS_FILE = Path("/root/hyper-factory/ai/memory/people/agents_levels.json")


def build_correct_agents():
    """
    تعريف الـ Agents الأساسية في الـ pipeline.
    الأرقام (salary_index / runs) هنا قيم افتراضية معقولة، يمكنك تعديلها لاحقاً إذا حبيت.
    """
    agents = [
        {
            "agent": "ingestor_basic",
            "family": "pipeline",
            "display_name": "عامل إدخال البيانات",
            "role": "data_ingestor",
            "level": "expert",
            "salary_index": 1.5,
            "total_runs": 16,
            "success_runs": 16,
            "failed_runs": 0,
        },
        {
            "agent": "processor_basic",
            "family": "pipeline",
            "display_name": "عامل معالجة البيانات",
            "role": "data_processor",
            "level": "expert",
            "salary_index": 1.65,
            "total_runs": 16,
            "success_runs": 16,
            "failed_runs": 0,
        },
        {
            "agent": "analyzer_basic",
            "family": "pipeline",
            "display_name": "عامل التحليل الدلالي",
            "role": "data_analyzer",
            "level": "expert",
            "salary_index": 1.8,
            "total_runs": 16,
            "success_runs": 16,
            "failed_runs": 0,
        },
        {
            "agent": "reporter_basic",
            "family": "pipeline",
            "display_name": "عامل التقارير والتقديم",
            "role": "data_reporter",
            "level": "expert",
            "salary_index": 1.65,
            "total_runs": 16,
            "success_runs": 16,
            "failed_runs": 0,
        },
    ]

    # حساب success_rate بشكل صريح
    for a in agents:
        tr = max(a.get("total_runs", 0), 1)
        sr = a.get("success_runs", 0)
        a["success_rate"] = round(sr / tr, 4)

    return agents


def fix_agents_data():
    print("🔧 بدء إصلاح بيانات الـ Agents...")
    if not AGENTS_FILE.parent.exists():
        print(f"ℹ️ إنشاء المجلد الهدف: {AGENTS_FILE.parent}")
        AGENTS_FILE.parent.mkdir(parents=True, exist_ok=True)

    correct_agents = build_correct_agents()

    with AGENTS_FILE.open("w", encoding="utf-8") as f:
        json.dump(correct_agents, f, ensure_ascii=False, indent=2)

    print("✅ تم كتابة ملف agents_levels.json بصيغة نظيفة.")
    print(f"📄 المسار: {AGENTS_FILE}")
    print("📊 الـ Agents المصححة:")
    for agent in correct_agents:
        print(
            f"   - {agent['agent']} [{agent['family']}] "
            f"level={agent['level']}, salary_index={agent['salary_index']}, "
            f"success_rate={agent['success_rate']:.2f}"
        )


if __name__ == "__main__":
    fix_agents_data()
