#!/usr/bin/env python3
"""
Patterns Engine – Hyper Factory
- قراءة قاعدة المعرفة
- حساب إحصاءات وأنماط بسيطة
- إخراج JSON + تقرير نصي
"""

import json
import sqlite3
from pathlib import Path
from datetime import datetime

BASE = Path(__file__).resolve().parents[2]  # /root/hyper-factory
DB_PATH = BASE / "data" / "knowledge" / "knowledge.db"
OUT_JSON = BASE / "ai" / "patterns" / "patterns_summary.json"
OUT_TXT = BASE / "reports" / "patterns" / "patterns_summary.txt"


def safe_count(cur, table: str) -> int:
    try:
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        (c,) = cur.fetchone()
        return int(c)
    except Exception:
        return -1


def analyze_patterns():
    print("🔍 Patterns Engine – بدء تحليل الأنماط")
    print(f"📁 قاعدة المعرفة: {DB_PATH}")

    if not DB_PATH.exists():
        print("❌ knowledge.db غير موجود – لا يمكن تشغيل محرك الأنماط.")
        return

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    tables = [
        "sources",
        "knowledge_items",
        "debug_knowledge",
        "web_knowledge",
        "programming_patterns",
        "knowledge_index",
        "system_patterns",
        "agent_memory",
        "debug_solutions",
    ]

    stats = {}
    total = 0
    for t in tables:
        cnt = safe_count(cur, t)
        stats[t] = {"count": cnt}
        if cnt > 0:
            total += cnt

    for t, info in stats.items():
        cnt = info["count"]
        if total > 0 and cnt >= 0:
            info["ratio"] = round(cnt / total, 4)
        else:
            info["ratio"] = None

    insights = []
    web_cnt = stats.get("web_knowledge", {}).get("count", 0)
    patt_cnt = stats.get("programming_patterns", {}).get("count", 0)
    sys_patt_cnt = stats.get("system_patterns", {}).get("count", 0)

    if web_cnt > 0:
        insights.append(
            f"هناك اعتماد قوي على web_knowledge بعدد {web_cnt} سجل."
        )
    if patt_cnt > 0:
        insights.append(
            f"مكتبة الأنماط البرمجية تحتوي على {patt_cnt} نمط."
        )
    if sys_patt_cnt == 0:
        insights.append(
            "جدول system_patterns فارغ → لم يتم تخزين أنماط تشغيلية بعد."
        )

    summary = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "db_path": str(DB_PATH),
        "total_records": total,
        "tables": stats,
        "insights": insights,
    }

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    with OUT_JSON.open("w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)

    OUT_TXT.parent.mkdir(parents=True, exist_ok=True)
    with OUT_TXT.open("w", encoding="utf-8") as f:
        f.write("📊 Patterns Engine – Summary\n")
        f.write(f"⏰ {summary['generated_at']}\n")
        f.write(f"DB: {summary['db_path']}\n\n")
        f.write("الجداول:\n")
        for t, info in stats.items():
            f.write(f"- {t}: count={info['count']}, ratio={info['ratio']}\n")
        f.write("\nاستنتاجات:\n")
        for ins in insights:
            f.write(f"- {ins}\n")

    print("✅ تم إنشاء ملفات ملخص الأنماط:")
    print(f"   - JSON: {OUT_JSON}")
    print(f"   - TEXT: {OUT_TXT}")


if __name__ == "__main__":
    analyze_patterns()
