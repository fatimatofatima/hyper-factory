#!/usr/bin/env python3
"""
Quality Engine – Hyper Factory
- تقييم جودة قاعدة المعرفة بأرقام بسيطة
- إخراج تقرير JSON + TXT على مستوى Business
"""

import json
import sqlite3
from pathlib import Path
from datetime import datetime

BASE = Path(__file__).resolve().parents[2]
DB_PATH = BASE / "data" / "knowledge" / "knowledge.db"
OUT_JSON = BASE / "ai" / "quality" / "knowledge_quality_report.json"
OUT_TXT = BASE / "reports" / "quality" / "knowledge_quality_report.txt"


def safe_count(cur, table: str) -> int:
    try:
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        (c,) = cur.fetchone()
        return int(c)
    except Exception:
        return -1


def grade_level(v: int, low: int, high: int) -> str:
    if v < 0:
        return "UNKNOWN"
    if v < low:
        return "LOW"
    if v < high:
        return "MEDIUM"
    return "HIGH"


def evaluate_quality():
    print("🧪 Quality Engine – تقييم جودة قاعدة المعرفة")
    print(f"📁 قاعدة المعرفة: {DB_PATH}")

    if not DB_PATH.exists():
        print("❌ knowledge.db غير موجود – لا يمكن تقييم الجودة.")
        return

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    sources = safe_count(cur, "sources")
    items = safe_count(cur, "knowledge_items")
    web = safe_count(cur, "web_knowledge")
    patterns = safe_count(cur, "programming_patterns")
    debug_solutions = safe_count(cur, "debug_solutions")

    coverage_ratio = (items / sources) if sources > 0 and items >= 0 else None
    enrichment_ratio = (web / items) if items > 0 and web >= 0 else None

    quality_score = 0
    if items > 0:
        quality_score += 30
    if web > 100:
        quality_score += 30
    if patterns > 0:
        quality_score += 20
    if debug_solutions > 0:
        quality_score += 20
    if quality_score > 100:
        quality_score = 100

    summary = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "db_path": str(DB_PATH),
        "metrics": {
            "sources_count": sources,
            "knowledge_items_count": items,
            "web_knowledge_count": web,
            "programming_patterns_count": patterns,
            "debug_solutions_count": debug_solutions,
            "coverage_ratio": coverage_ratio,
            "enrichment_ratio": enrichment_ratio,
        },
        "grades": {
            "coverage_level": grade_level(items, 5, 20),
            "enrichment_level": grade_level(web, 50, 200),
            "patterns_level": grade_level(patterns, 1, 5),
        },
        "quality_score": quality_score,
    }

    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    with OUT_JSON.open("w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)

    OUT_TXT.parent.mkdir(parents=True, exist_ok=True)
    with OUT_TXT.open("w", encoding="utf-8") as f:
        f.write("🧪 Knowledge Quality Report – Hyper Factory\n")
        f.write(f"⏰ {summary['generated_at']}\n\n")
        f.write("المؤشرات:\n")
        for k, v in summary["metrics"].items():
            f.write(f"- {k}: {v}\n")
        f.write("\nالتصنيفات:\n")
        for k, v in summary["grades"].items():
            f.write(f"- {k}: {v}\n")
        f.write(f"\n📈 Quality Score: {summary['quality_score']} / 100\n")

    print("✅ تم إنشاء تقرير جودة قاعدة المعرفة:")
    print(f"   - JSON: {OUT_JSON}")
    print(f"   - TEXT: {OUT_TXT}")


if __name__ == "__main__":
    evaluate_quality()
