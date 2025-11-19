#!/usr/bin/env python3
import os
import json
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent
LESSONS_DIR = ROOT / "ai" / "memory" / "lessons"
PLAN_PATH = ROOT / "reports" / "management" / "lessons_apply_plan.md"
AGENTS_DIFF = ROOT / "config_changes" / "agents.diff"
FACTORY_DIFF = ROOT / "config_changes" / "factory.diff"

def load_lessons():
    if not LESSONS_DIR.exists():
        return []

    lessons = []
    for path in sorted(LESSONS_DIR.glob("*.json")):
        try:
            with open(path, "r", encoding="utf-8") as f:
                obj = json.load(f)
            obj["_file"] = path
            lessons.append(obj)
        except Exception as e:
            print(f"[WARN] تعذر قراءة ملف درس: {path} ({e})")
    return lessons

def main():
    LESSONS_DIR.mkdir(parents=True, exist_ok=True)
    PLAN_PATH.parent.mkdir(parents=True, exist_ok=True)
    AGENTS_DIFF.parent.mkdir(parents=True, exist_ok=True)

    lessons = load_lessons()
    now = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

    # 1) خطة تطبيق الدروس (Markdown)
    with open(PLAN_PATH, "w", encoding="utf-8") as f:
        f.write("# Hyper Factory – خطة تطبيق الدروس (Lessons Apply Plan)\n")
        f.write(f"Generated at (UTC): {now}\n\n")

        if not lessons:
            f.write("لا توجد دروس حالياً في ai/memory/lessons.\n")
        else:
            f.write(f"إجمالي الدروس المقروءة: {len(lessons)}\n\n")
            for idx, l in enumerate(lessons, start=1):
                f.write(f"## درس رقم {idx}\n")
                f.write(f"- ID        : {l.get('id')}\n")
                f.write(f"- item_key  : {l.get('item_key')}\n")
                f.write(f"- title     : {l.get('title', '')}\n")
                f.write(f"- importance: {l.get('importance', 0.0)}\n")
                f.write(f"- tags      : {', '.join(l.get('tags', []))}\n")
                f.write(f"- file      : {l.get('_file').relative_to(ROOT)}\n")
                f.write("\n")
                body = (l.get("body") or "").strip()
                if body:
                    f.write("### نص الدرس (body)\n\n")
                    f.write(body + "\n\n")
                meta = l.get("meta") or {}
                if meta:
                    f.write("### Meta\n\n")
                    f.write("```json\n")
                    f.write(json.dumps(meta, ensure_ascii=False, indent=2))
                    f.write("\n```\n\n")

            f.write("---\n")
            f.write("ملاحظة: الخطوة التالية هي تحويل هذه الدروس إلى تغييرات فعلية في:\n")
            f.write("- config/agents.yaml\n")
            f.write("- config/factory.yaml\n")
            f.write("يمكن الاستعانة بملفات diff المقترحة في مجلد config_changes/.\n")

    # 2) ملفات diff مقترحة (Placeholder / Basis)
    # لن نعبّئها تلقائياً الآن، فقط نضع header موحّد + قائمة الدروس
    header = [
        "# Hyper Factory – Suggested Config Changes based on Lessons",
        f"Generated at (UTC): {now}",
        "",
        "هذه الملفات عبارة عن نقطة بداية لتطبيق الدروس على ملفات الإعدادات.",
        "يتم تحريرها يدوياً الآن، ويمكن لاحقاً أتمتة جزء من المنطق.",
        "",
        "الدروس المدخلة:",
    ]

    lesson_lines = []
    for l in lessons:
        line = f"- [{l.get('item_key')}] {l.get('title', '')} (importance={l.get('importance', 0.0)})"
        lesson_lines.append(line)

    content = "\n".join(header + (lesson_lines or ["- لا توجد دروس حالياً."])) + "\n\n"
    content += "## Patch Zone\n"
    content += "هنا يمكنك إضافة التغييرات المقترحة بصيغة unified diff على ملفات config.\n"

    with open(AGENTS_DIFF, "w", encoding="utf-8") as f:
        f.write(content)
        f.write("\n# Target file: config/agents.yaml\n")

    with open(FACTORY_DIFF, "w", encoding="utf-8") as f:
        f.write(content)
        f.write("\n# Target file: config/factory.yaml\n")

    print("[DONE] تم بناء خطة تطبيق الدروس وملفات diff المقترحة.")
    print(f" - خطة التطبيق : {PLAN_PATH}")
    print(f" - agents.diff : {AGENTS_DIFF}")
    print(f" - factory.diff: {FACTORY_DIFF}")

if __name__ == "__main__":
    main()
