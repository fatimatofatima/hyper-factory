#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
hf_import_agent_levels_to_knowledge.py

استيراد مستويات الـ Agents من:
  ai/memory/people/agents_levels.json

وكتابة عناصر معرفة من نوع:
  item_type = "agent_level"

داخل:
  data/knowledge/knowledge.db
  جدول: knowledge_items

مصمم ليكون متوافق مع سكيمة الجدول الموجودة فعليًا:
- يعتمد على introspection عبر PRAGMA table_info
- يستخدم الأعمدة المتاحة فقط.
"""

import json
import sqlite3
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent
AGENTS_FILE = ROOT / "ai" / "memory" / "people" / "agents_levels.json"
DB_PATH = ROOT / "data" / "knowledge" / "knowledge.db"
TABLE_NAME = "knowledge_items"


def load_agents():
    if not AGENTS_FILE.exists():
        print(f"⚠️ ملف Agents غير موجود: {AGENTS_FILE}")
        return []

    try:
        data = json.loads(AGENTS_FILE.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"⚠️ فشل قراءة JSON من {AGENTS_FILE}: {e}")
        return []

    # نتوقع list[dict]
    if isinstance(data, dict):
        # fallback قديم (لو كان الشكل map)
        items = []
        for k, v in data.items():
            if isinstance(v, dict):
                v.setdefault("agent", k)
                items.append(v)
        return items
    elif isinstance(data, list):
        return [x for x in data if isinstance(x, dict)]
    else:
        print("⚠️ شكل agents_levels.json غير مدعوم (ليس dict أو list).")
        return []


def get_columns(conn):
    cur = conn.execute(f"PRAGMA table_info({TABLE_NAME})")
    cols = [row[1] for row in cur.fetchall()]
    return cols


def main():
    agents = load_agents()
    if not agents:
        print("ℹ️ لا توجد بيانات Agents صالحة للاستيراد.")
        return

    if not DB_PATH.exists():
        print(f"⚠️ ملف قاعدة المعرفة غير موجود: {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    try:
        cols = get_columns(conn)
        if not cols:
            print(f"⚠️ تعذّر قراءة أعمدة الجدول {TABLE_NAME}.")
            return

        required = ["item_type", "key", "payload_json"]
        for c in required:
            if c not in cols:
                print(f"⚠️ العمود '{c}' غير موجود في {TABLE_NAME}، لن يتم الإدخال.")
                return

        # أعمدة اختيارية
        optional = []
        if "title" in cols:
            optional.append("title")
        if "tags" in cols:
            optional.append("tags")
        if "created_at" in cols:
            optional.append("created_at")

        insert_cols = required + optional
        placeholders = ",".join([f":{c}" for c in insert_cols])
        cols_sql = ",".join(insert_cols)
        sql = f"INSERT OR REPLACE INTO {TABLE_NAME} ({cols_sql}) VALUES ({placeholders})"

        now = datetime.utcnow().isoformat() + "Z"

        cursor = conn.cursor()
        inserted = 0

        for ag in agents:
            agent_id = ag.get("agent") or ag.get("name")
            if not agent_id:
                continue

            level = ag.get("level", "unknown")
            family = ag.get("family", "unknown")
            display_name = ag.get("display_name", agent_id)
            success_rate = ag.get("success_rate")
            salary_index = ag.get("salary_index")
            total_runs = ag.get("total_runs")
            success_runs = ag.get("success_runs")
            failed_runs = ag.get("failed_runs")

            payload = {
                "agent": agent_id,
                "display_name": display_name,
                "family": family,
                "role": ag.get("role"),
                "level": level,
                "success_rate": success_rate,
                "salary_index": salary_index,
                "total_runs": total_runs,
                "success_runs": success_runs,
                "failed_runs": failed_runs,
            }

            # بناء الحقول حسب الأعمدة المتاحة
            row = {
                "item_type": "agent_level",
                "key": agent_id,
                "payload_json": json.dumps(payload, ensure_ascii=False),
            }

            if "title" in insert_cols:
                row["title"] = f"{display_name} ({agent_id})"

            if "tags" in insert_cols:
                tags = [
                    "agent",
                    f"family={family}",
                    f"level={level}",
                ]
                if success_rate is not None:
                    try:
                        tags.append(f"success_rate={float(success_rate):.2f}")
                    except Exception:
                        pass
                row["tags"] = ",".join(tags)

            if "created_at" in insert_cols:
                row["created_at"] = now

            cursor.execute(sql, row)
            inserted += 1

        conn.commit()
        print(f"✅ تم استيراد/تحديث {inserted} عنصر معرفة من نوع 'agent_level' في جدول {TABLE_NAME}.")
    finally:
        conn.close()
        print(f"📄 قاعدة المعرفة المستخدمة: {DB_PATH}")


if __name__ == "__main__":
    main()
