#!/usr/bin/env python3
"""
تحضير قاعدة المعرفة:
- إنشاء ملف data/knowledge/knowledge.db إذا لم يكن موجوداً
- إنشاء الجداول الأساسية إذا كانت مفقودة:
  * web_knowledge       (لما يجمعه Web Spider)
  * debug_solutions     (لـ Debug Expert)
"""

import os
import sqlite3
from datetime import datetime

DB_PATH = "data/knowledge/knowledge.db"

def ensure_dirs():
    os.makedirs("data/knowledge", exist_ok=True)

def prepare_db():
    ensure_dirs()
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    # جدول نتائج الزاحف (احتياطي؛ Web Spider المصحح أيضاً ينشئ ما يحتاجه)
    cur.execute("""
        CREATE TABLE IF NOT EXISTS web_knowledge (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT,
            title TEXT,
            content TEXT,
            source TEXT,
            created_at TEXT
        )
    """)

    # جدول حلول الأخطاء لـ Debug Expert
    cur.execute("""
        CREATE TABLE IF NOT EXISTS debug_solutions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            error_pattern TEXT NOT NULL,
            solution TEXT NOT NULL,
            confidence REAL DEFAULT 0.0,
            tags TEXT,
            created_at TEXT DEFAULT (datetime('now'))
        )
    """)

    conn.commit()
    conn.close()
    print(f"✅ تم تحضير قاعدة المعرفة في {DB_PATH}")

if __name__ == "__main__":
    prepare_db()
