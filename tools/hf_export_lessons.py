#!/usr/bin/env python3
import os
import sqlite3
import json
import re
from pathlib import Path

def sanitize_filename(name: str) -> str:
    if not name:
        return "lesson"
    # نسمح فقط بالحروف والأرقام والشرطة والشرطة السفلية
    return re.sub(r'[^a-zA-Z0-9_-]+', '_', name)[:60]

def main():
    root = Path(__file__).resolve().parent.parent
    db_path = root / "data" / "knowledge" / "knowledge.db"
    out_dir = root / "ai" / "memory" / "lessons"
    out_dir.mkdir(parents=True, exist_ok=True)

    if not db_path.exists():
        print(f"[ERROR] قاعدة المعرفة غير موجودة: {db_path}")
        return

    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    # نقرأ عناصر نوع lesson فقط
    cur.execute("""
        SELECT id, item_key, title, body, importance, tags,
               created_at, updated_at, meta_json
        FROM knowledge_items
        WHERE item_type = 'lesson'
        ORDER BY id ASC
    """)

    rows = cur.fetchall()
    if not rows:
        print("[INFO] لا توجد عناصر lesson في knowledge_items. لا يوجد ما يُصدَّر.")
        return

    exported = 0
    for row in rows:
        lesson_id = row["id"]
        item_key = row["item_key"] or f"lesson_{lesson_id}"
        title = row["title"]
        body = row["body"]
        importance = row["importance"]
        tags = row["tags"] or ""
        created_at = row["created_at"]
        updated_at = row["updated_at"]
        meta_json = row["meta_json"]

        # نحاول قراءة meta_json كـ JSON، وإن فشل نضعه كـ نص خام
        meta = {}
        if meta_json:
            try:
                meta = json.loads(meta_json)
            except Exception:
                meta = {"raw_meta_json": meta_json}

        lesson_obj = {
            "id": lesson_id,
            "item_key": item_key,
            "title": title,
            "body": body,
            "importance": importance,
            "tags": [t for t in tags.split(",") if t.strip()] if tags else [],
            "created_at": created_at,
            "updated_at": updated_at,
            "meta": meta
        }

        safe_key = sanitize_filename(item_key)
        filename = f"lesson_{lesson_id:04d}_{safe_key}.json"
        out_path = out_dir / filename

        with out_path.open("w", encoding="utf-8") as f:
            json.dump(lesson_obj, f, ensure_ascii=False, indent=2)

        exported += 1
        print(f"[OK] Exported lesson #{lesson_id} -> {out_path}")

    conn.close()
    print(f"[DONE] Exported {exported} lessons to {out_dir}")

if __name__ == "__main__":
    main()
