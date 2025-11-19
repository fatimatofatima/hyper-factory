#!/usr/bin/env python3
"""
tools/hf_apply_lessons.py

Apply Lessons (Dry-Run Config Advisor):
- يقرأ كل ملفات ai/memory/lessons/*.json
- يجمع الـ Actions المسجّلة (id/title/priority/description)
- ينتج:
  - reports/config_changes/{timestamp}_lessons_summary.txt
  - reports/config_changes/{timestamp}_agents.diff   (قالب يدوي)
  - reports/config_changes/{timestamp}_factory.diff  (قالب يدوي)
لا يقوم بأي تعديل على config/ تلقائيًا؛ فقط يجهّز ملفات للمراجعة اليدوية.
"""

import os
import json
from datetime import datetime
from typing import List, Dict, Any

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

MEMORY_DIR = ROOT / "ai" / "memory"
LESSONS_DIR = MEMORY_DIR / "lessons"

REPORTS_DIR = ROOT / "reports"
CONFIG_CHANGES_DIR = REPORTS_DIR / "config_changes"


def load_lessons() -> List[Dict[str, Any]]:
    lessons_files = sorted(LESSONS_DIR.glob("*.json"))
    if not lessons_files:
        print("ℹ️ لا توجد ملفات lessons في ai/memory/lessons/*.json حتى الآن.")
        return []

    all_actions: List[Dict[str, Any]] = []

    for path in lessons_files:
        try:
            with path.open("r", encoding="utf-8") as f:
                data = json.load(f)
        except Exception as e:
            print(f"⚠️ تعذّر قراءة ملف lessons: {path} ({e})")
            continue

        date = data.get("date")
        actions = data.get("actions", [])
        for act in actions:
            all_actions.append(
                {
                    "source_file": str(path.name),
                    "date": date,
                    "id": act.get("id"),
                    "title": act.get("title"),
                    "priority": act.get("priority"),
                    "description": act.get("description"),
                }
            )

    return all_actions


def main() -> None:
    print(f"📁 ROOT        : {ROOT}")
    print(f"📂 LESSONS_DIR : {LESSONS_DIR}")
    print(f"📂 REPORTS_DIR : {REPORTS_DIR}")
    print("----------------------------------------")

    CONFIG_CHANGES_DIR.mkdir(parents=True, exist_ok=True)

    actions = load_lessons()
    if not actions:
        print("ℹ️ لا توجد Actions لاستخلاصها من lessons. لا شيء للكتابة.")
        return

    ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    summary_path = CONFIG_CHANGES_DIR / f"{ts}_lessons_summary.txt"
    agents_diff_path = CONFIG_CHANGES_DIR / f"{ts}_agents.diff"
    factory_diff_path = CONFIG_CHANGES_DIR / f"{ts}_factory.diff"

    # كتابة ملف الملخص النصي
    lines: List[str] = []
    lines.append("===== Hyper Factory Lessons Summary =====")
    lines.append(f"Generated at : {datetime.utcnow().isoformat()}Z")
    lines.append(f"Total actions: {len(actions)}")
    lines.append("")
    lines.append("== Actions ==")

    for idx, act in enumerate(actions, start=1):
        lines.append(f"[{idx}] id={act.get('id')}")
        lines.append(f"    title      : {act.get('title')}")
        lines.append(f"    priority   : {act.get('priority')}")
        lines.append(f"    date       : {act.get('date')}")
        lines.append(f"    source     : {act.get('source_file')}")
        lines.append("    description:")
        desc = act.get("description") or ""
        for dline in str(desc).splitlines():
            lines.append(f"      - {dline}")
        lines.append("")

    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    # قوالب diff مبدئية (تعليقات فقط) للمراجعة اليدوية
    header = []
    header.append("# Hyper Factory Config Changes (DRAFT / MANUAL)")
    header.append(f"# Generated at : {datetime.utcnow().isoformat()}Z")
    header.append(f"# Total actions: {len(actions)}")
    header.append("# NOTE: هذا الملف لا يُطبّق تلقائيًا؛ استخدمه كقالب لتعديل config/ بعد مراجعة بشرية.")
    header.append("#")
    header.append("# لكل Action أدناه، قرّر يدويًا هل التأثير على agents.yaml أو factory.yaml أو الإعدادات التشغيلية.")
    header.append("")

    agents_lines = list(header)
    agents_lines.append("# === Candidate changes for config/agents.yaml ===")
    agents_lines.append("#")

    factory_lines = list(header)
    factory_lines.append("# === Candidate changes for config/factory.yaml ===")
    factory_lines.append("#")

    for idx, act in enumerate(actions, start=1):
        base = [
            f"# [{idx}] id={act.get('id')} | priority={act.get('priority')}",
            f"# title   : {act.get('title')}",
            f"# date    : {act.get('date')} | source: {act.get('source_file')}",
            "# description:",
        ]
        desc = act.get("description") or ""
        for dline in str(desc).splitlines():
            base.append(f"#   {dline}")
        base.append("# TODO: حدّد إذا كان هذا الدرس يتطلّب تعديل عامل (agent) معيّن أو إعدادات المصنع (factory).")
        base.append("# TODO: استبدل هذا التعليق ببلوك diff فعلي بعد اتخاذ القرار.")
        base.append("#")

        # حالياً نكرّر نفس البلوك في الملفين، والقرار النهائي يكون يدوي
        agents_lines.extend(base)
        factory_lines.extend(base)

    agents_diff_path.write_text("\n".join(agents_lines) + "\n", encoding="utf-8")
    factory_diff_path.write_text("\n".join(factory_lines) + "\n", encoding="utf-8")

    print("✅ تم توليد ملفات Apply Lessons (Draft):")
    print(f"   - {summary_path}")
    print(f"   - {agents_diff_path}")
    print(f"   - {factory_diff_path}")


if __name__ == "__main__":
    main()
