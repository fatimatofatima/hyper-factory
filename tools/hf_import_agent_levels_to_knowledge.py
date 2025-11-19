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

- يعتمد على introspection عبر PRAGMA table_info
- يستخدم الأعمدة المتاحة فقط (بدون افتراض وجود عمود key).
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
        print(f"⚠️ ملف agents_levels غير موجود: {AGENTS_FILE}")
        return []

    try:
        data = json.loads(AGENTS_FILE.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"⚠️ تعذّر قراءة agents_levels.json: {e}")
        return []

    if not isinstance(data, list):
        print("⚠️ شكل agents_levels.json غير مدعوم (ليس list).")
        return []

    agents = []
    for item in data:
        if not isinstance(item, dict):
            continue
        agent_id = item.get("agent") or item.get("id")
        if not agent_id:
            continue
        agents.append(item)
    return agents


def get_table_columns(cur):
    cur.execute(f"PRAGMA table_info({TABLE_NAME})")
    rows = cur.fetchall()
    if not rows:
        print(f"⚠️ تعذّر قراءة أعمدة الجدول {TABLE_NAME} (ربما غير موجود).")
        return []
    cols = [r[1] for r in rows]
    print(f"📊 أعمدة {TABLE_NAME}: {cols}")
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
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    cols = get_table_columns(cur)
    if "item_type" not in cols:
        print(f"⚠️ العمود 'item_type' غير موجود في {TABLE_NAME}، لا يمكن الإدخال.")
        conn.close()
        return

    # حذف أي عناصر قديمة من نوع agent_level (لو أمكن)
    try:
        cur.execute(
            f"DELETE FROM {TABLE_NAME} WHERE item_type = ?",
            ("agent_level",),
        )
        deleted = cur.rowcount
        print(f"🧹 حذف {deleted} عنصر سابق من نوع agent_level (إن وجد).")
    except Exception as e:
        print(f"⚠️ تعذر حذف العناصر السابقة من {TABLE_NAME}: {e}")

    now = datetime.utcnow().isoformat(timespec="seconds") + "Z"
    inserted = 0

    for item in agents:
        agent_id = item.get("agent") or item.get("id")
        family = item.get("family", "")
        role = item.get("role", "")
        display_name = item.get("display_name") or agent_id
        level = item.get("level", "")
        salary_index = item.get("salary_index")
        success_rate = item.get("success_rate")
        total_runs = item.get("total_runs")
        success_runs = item.get("success_runs")
        failed_runs = item.get("failed_runs")

        # payload الأساسي داخل content / extra_json
        details = {
            "agent": agent_id,
            "family": family,
            "role": role,
            "display_name": display_name,
            "level": level,
            "salary_index": salary_index,
            "success_rate": success_rate,
            "total_runs": total_runs,
            "success_runs": success_runs,
            "failed_runs": failed_runs,
        }

        row = {}
        # أعمدة قياسية إن وجدت
        if "item_type" in cols:
            row["item_type"] = "agent_level"
        if "title" in cols:
            row["title"] = f"مستوى العامل {display_name} ({agent_id})"
        if "content" in cols:
            row["content"] = json.dumps(
                details, ensure_ascii=False, separators=(",", ":")
            )
        if "source" in cols:
            row["source"] = "hf_roles_engine"
        if "created_at" in cols:
            row["created_at"] = now
        if "tags" in cols:
            row["tags"] = "agent,level,pipeline"
        if "key" in cols:
            # نستخدم agent_id كمفتاح لو العمود موجود
            row["key"] = str(agent_id)
        if "extra_json" in cols:
            row["extra_json"] = json.dumps(
                {"kind": "agent_level", "agent": agent_id}, ensure_ascii=False
            )

        if len(row) <= 1:  # فقط item_type تقريبًا
            print(f"⚠️ تخطي agent={agent_id}: لا توجد أعمدة كافية للإدخال.")
            continue

        columns = ",".join(row.keys())
        placeholders = ",".join(["?"] * len(row))
        values = list(row.values())

        try:
            cur.execute(
                f"INSERT INTO {TABLE_NAME} ({columns}) VALUES ({placeholders})",
                values,
            )
            inserted += 1
        except Exception as e:
            print(f"⚠️ فشل إدخال agent={agent_id}: {e}")

    conn.commit()
    conn.close()

    print(f"✅ تم استيراد {inserted} عنصر agent_level إلى {DB_PATH}")


if __name__ == "__main__":
    main()
