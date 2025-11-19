#!/usr/bin/env python3
import os
import json
import sqlite3
from pathlib import Path
import re
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "data" / "knowledge" / "knowledge.db"
LESSONS_DIR = ROOT / "ai" / "memory" / "lessons"
REPORT_PATH = ROOT / "reports" / "management" / "lessons_export_report.txt"

def safe_slug(text: str, default: str = "lesson") -> str:
    if not text:
        return default
    text = text.strip().lower()
    text = re.sub(r"[^a-zA-Z0-9_\-]+", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")
    return text or default

def load_meta(meta_json):
    if not meta_json:
        return {}
    try:
        return json.loads(meta_json)
    except Exception:
        return {"raw_meta_json": meta_json}

def main():
    if not DB_PATH.exists():
        print(f"[ERROR] knowledge.db غير موجود: {DB_PATH}")
        return

    LESSONS_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    cur.execute("""
        SELECT id, item_key, title, body, importance, tags, created_at, updated_at, meta_json
        FROM knowledge_items
        WHERE item_type = 'lesson'
        ORDER BY id ASC
    """)
    rows = cur.fetchall()
    conn.close()

    if not rows:
        print("[INFO] لا توجد عناصر lesson في knowledge_items.")
        with open(REPORT_PATH, "w", encoding="utf-8") as f:
            f.write("# Hyper Factory – Lessons Export Report\n")
            f.write("لا توجد عناصر من نوع lesson في قاعدة المعرفة.\n")
        return

    exported = []
    for r in rows:
        item_id = r["id"]
        item_key = r["item_key"] or f"lesson_{item_id}"
        title = r["title"] or ""
        body = r["body"] or ""
        importance = r["importance"] if r["importance"] is not None else 0.0
        tags = (r["tags"] or "").split(",") if r["tags"] else []
        created_at = r["created_at"] or ""
        updated_at = r["updated_at"] or ""
        meta = load_meta(r["meta_json"])

        slug = safe_slug(item_key, default=f"lesson_{item_id}")
        filename = f"{item_id:04d}_{slug}.json"
        out_path = LESSONS_DIR / filename

        lesson_obj = {
            "id": item_id,
            "item_key": item_key,
            "title": title,
            "body": body,
            "importance": importance,
            "tags": tags,
            "created_at": created_at,
            "updated_at": updated_at,
            "meta": meta,
        }

        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(lesson_obj, f, ensure_ascii=False, indent=2)

        exported.append(out_path)

    # تقرير مختصر
    now = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        f.write("# Hyper Factory – Lessons Export Report\n")
        f.write(f"Generated at (UTC): {now}\n\n")
        f.write(f"إجمالي الدروس في DB  : {len(rows)}\n")
        f.write(f"تم تصدير الدروس إلى   : {LESSONS_DIR}\n\n")
        f.write("الملفات المصدّرة:\n")
        for p in exported:
            f.write(f"- {p.relative_to(ROOT)}\n")

    print(f"[DONE] تم تصدير {len(exported)} درس/دروس إلى {LESSONS_DIR}")
    print(f"[INFO] تقرير التصدير: {REPORT_PATH}")

if __name__ == "__main__":
    main()
