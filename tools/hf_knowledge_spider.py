#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
hf_knowledge_spider.py

Knowledge Spider لـ Hyper Factory:
- الهدف: جمع المعرفة المتولّدة من المصنع (KPIs, Lessons, Curriculum, Agents, Insights...)
  وتحويلها إلى قاعدة بيانات منظمة للمعرفة يمكن استجوابها لاحقًا.

المصادر الحالية:
  1) data/report/summary_basic.json             → عناصر من نوع "kpi"
  2) ai/memory/lessons/*.json                   → عناصر من نوع "lesson"
  3) ai/memory/curriculum/roadmap.json          → عناصر من نوع "curriculum_phase"
  4) ai/memory/people/agents_levels.json        → عناصر من نوع "agent_level"
  5) ai/memory/insights.json (إن وجد)          → عناصر من نوع "insight"

المخرجات:
  - SQLite DB في: data/knowledge/knowledge.db
    * جدول sources
    * جدول knowledge_items

سياسة العمل:
  - لا حذف لشيء؛ نستخدم INSERT OR REPLACE مع مفتاح (source_key, item_type, item_key).
  - لا تعديل لأي ملفات config أو pipeline.
"""

import json
import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, Optional

ROOT = Path("/root/hyper-factory").resolve()
DATA_DIR = ROOT / "data"
KNOWLEDGE_DIR = DATA_DIR / "knowledge"
DB_PATH = KNOWLEDGE_DIR / "knowledge.db"

SUMMARY_BASIC_PATH = ROOT / "data" / "report" / "summary_basic.json"
LESSONS_DIR = ROOT / "ai" / "memory" / "lessons"
ROADMAP_PATH = ROOT / "ai" / "memory" / "curriculum" / "roadmap.json"
AGENTS_LEVELS_PATH = ROOT / "ai" / "memory" / "people" / "agents_levels.json"
INSIGHTS_PATH = ROOT / "ai" / "memory" / "insights.json"


def load_json(path: Path) -> Optional[Any]:
    if not path.is_file():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"⚠️ فشل قراءة JSON من {path}: {e}")
        return None


def init_db() -> sqlite3.Connection:
    KNOWLEDGE_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS sources (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_key TEXT UNIQUE,
            source_type TEXT,
            path TEXT,
            meta_json TEXT,
            created_at TEXT,
            updated_at TEXT
        );
        """
    )
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS knowledge_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_id INTEGER NOT NULL,
            item_type TEXT NOT NULL,
            item_key TEXT NOT NULL,
            title TEXT,
            body TEXT,
            importance REAL,
            tags TEXT,
            created_at TEXT,
            updated_at TEXT,
            meta_json TEXT,
            UNIQUE(source_id, item_type, item_key),
            FOREIGN KEY (source_id) REFERENCES sources(id)
        );
        """
    )
    conn.commit()
    return conn


def upsert_source(
    conn: sqlite3.Connection,
    source_key: str,
    source_type: str,
    path: str,
    meta: Optional[Dict[str, Any]] = None,
) -> int:
    now = datetime.utcnow().isoformat() + "Z"
    meta_json = json.dumps(meta or {}, ensure_ascii=False)
    conn.execute(
        """
        INSERT INTO sources (source_key, source_type, path, meta_json, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(source_key) DO UPDATE SET
            source_type=excluded.source_type,
            path=excluded.path,
            meta_json=excluded.meta_json,
            updated_at=excluded.updated_at;
        """,
        (source_key, source_type, path, meta_json, now, now),
    )
    conn.commit()
    cur = conn.execute("SELECT id FROM sources WHERE source_key=?", (source_key,))
    row = cur.fetchone()
    return int(row[0])


def upsert_item(
    conn: sqlite3.Connection,
    source_id: int,
    item_type: str,
    item_key: str,
    title: str,
    body: str,
    importance: float,
    tags: str,
    meta: Optional[Dict[str, Any]] = None,
) -> None:
    now = datetime.utcnow().isoformat() + "Z"
    meta_json = json.dumps(meta or {}, ensure_ascii=False)
    conn.execute(
        """
        INSERT INTO knowledge_items
          (source_id, item_type, item_key, title, body, importance, tags, created_at, updated_at, meta_json)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(source_id, item_type, item_key) DO UPDATE SET
          title=excluded.title,
          body=excluded.body,
          importance=excluded.importance,
          tags=excluded.tags,
          updated_at=excluded.updated_at,
          meta_json=excluded.meta_json;
        """,
        (
            source_id,
            item_type,
            item_key,
            title,
            body,
            importance,
            tags,
            now,
            now,
            meta_json,
        ),
    )


def spider_kpis(conn: sqlite3.Connection) -> int:
    data = load_json(SUMMARY_BASIC_PATH)
    if not isinstance(data, dict):
        print(f"ℹ️ لا يمكن قراءة KPIs من {SUMMARY_BASIC_PATH}")
        return 0

    source_id = upsert_source(
        conn,
        source_key="summary_basic",
        source_type="kpi",
        path=str(SUMMARY_BASIC_PATH),
        meta={"origin": "data/report/summary_basic.json"},
    )

    total = (
        data.get("total_runs")
        or data.get("runs_total")
        or data.get("runs")
        or data.get("count_runs")
    )
    success = (
        data.get("success_runs")
        or data.get("ok_runs")
        or data.get("runs_success")
        or data.get("success_count")
    )
    failed = (
        data.get("failed_runs")
        or data.get("error_runs")
        or data.get("runs_failed")
        or data.get("failed_count")
    )
    days = data.get("days_observed") or data.get("unique_days")

    if total is None and isinstance(success, (int, float)) and isinstance(
        failed, (int, float)
    ):
        total = success + failed

    if failed is None and isinstance(total, (int, float)) and isinstance(
        success, (int, float)
    ):
        failed = total - success

    success_rate = None
    if isinstance(total, (int, float)) and total > 0 and isinstance(
        success, (int, float)
    ):
        success_rate = float(success) * 100.0 / float(total)

    body_lines = []
    body_lines.append(f"total_runs={total}")
    body_lines.append(f"success_runs={success}")
    body_lines.append(f"failed_runs={failed}")
    body_lines.append(f"days_observed={days}")
    if success_rate is not None:
        body_lines.append(f"success_rate={success_rate:.2f}%")

    body = "\n".join(body_lines)
    upsert_item(
        conn,
        source_id=source_id,
        item_type="kpi",
        item_key="basic_pipeline",
        title="Hyper Factory basic pipeline KPIs",
        body=body,
        importance=1.0,
        tags="kpi,basic_pipeline",
        meta={
            "total_runs": total,
            "success_runs": success,
            "failed_runs": failed,
            "days_observed": days,
            "success_rate": success_rate,
        },
    )
    return 1


def spider_lessons(conn: sqlite3.Connection) -> int:
    if not LESSONS_DIR.is_dir():
        print(f"ℹ️ لا يوجد مجلد lessons: {LESSONS_DIR}")
        return 0

    files = sorted(LESSONS_DIR.glob("*.json"))
    if not files:
        print(f"ℹ️ لا توجد ملفات lessons في: {LESSONS_DIR}")
        return 0

    count = 0
    for path in files:
        data = load_json(path)
        if not isinstance(data, dict):
            continue

        source_key = f"lessons::{path.name}"
        source_id = upsert_source(
            conn,
            source_key=source_key,
            source_type="lesson_file",
            path=str(path),
            meta={"file": path.name},
        )

        actions = data.get("actions") or data.get("lessons") or []
        for idx, a in enumerate(actions, start=1):
            if not isinstance(a, dict):
                continue
            aid = str(a.get("id") or f"{path.stem}_{idx}")
            title = a.get("title") or a.get("name") or f"Lesson {idx}"
            priority = str(a.get("priority") or "MEDIUM").upper()
            pr_weight = {"HIGH": 1.0, "MEDIUM": 0.7, "LOW": 0.4}.get(priority, 0.5)
            date_str = str(a.get("date") or a.get("day") or "")

            if isinstance(a.get("description"), list):
                body = "\n".join(str(x) for x in a["description"])
            else:
                body = str(a.get("description") or "")

            tags = f"lesson,{priority.lower()}"
            meta = {
                "priority": priority,
                "date": date_str,
                "source_file": path.name,
            }
            upsert_item(
                conn,
                source_id=source_id,
                item_type="lesson",
                item_key=aid,
                title=title,
                body=body,
                importance=pr_weight,
                tags=tags,
                meta=meta,
            )
            count += 1

    return count


def spider_curriculum(conn: sqlite3.Connection) -> int:
    data = load_json(ROADMAP_PATH)
    if not isinstance(data, dict):
        print(f"ℹ️ لا يمكن قراءة roadmap من {ROADMAP_PATH}")
        return 0

    source_id = upsert_source(
        conn,
        source_key="curriculum::roadmap",
        source_type="curriculum",
        path=str(ROADMAP_PATH),
        meta={"origin": "ai/memory/curriculum/roadmap.json"},
    )

    phases_raw = []
    if isinstance(data.get("phases"), list):
        phases_raw = data["phases"]
    elif isinstance(data.get("items"), list):
        phases_raw = data["items"]

    count = 0
    for idx, p in enumerate(phases_raw, start=1):
        if not isinstance(p, dict):
            continue
        key = str(p.get("id") or p.get("name") or p.get("title") or f"phase_{idx}")
        title = p.get("name") or p.get("title") or f"Phase {idx}"
        summary = p.get("summary") or p.get("description") or ""
        days = p.get("days") or p.get("days_observed")
        avg_success = p.get("avg_success_rate")
        failed_runs = p.get("failed_runs")
        is_current = bool(p.get("is_current"))

        body_lines = [summary]
        body = "\n".join([line for line in body_lines if line])

        tags = "curriculum_phase"
        if is_current:
            tags += ",current"

        meta = {
            "days": days,
            "avg_success_rate": avg_success,
            "failed_runs": failed_runs,
            "is_current": is_current,
        }

        upsert_item(
            conn,
            source_id=source_id,
            item_type="curriculum_phase",
            item_key=key,
            title=title,
            body=body,
            importance=1.0 if is_current else 0.7,
            tags=tags,
            meta=meta,
        )
        count += 1

    return count


def spider_agents_levels(conn: sqlite3.Connection) -> int:
    data = load_json(AGENTS_LEVELS_PATH)
    if not isinstance(data, dict):
        print(f"ℹ️ لا يمكن قراءة agents_levels من {AGENTS_LEVELS_PATH}")
        return 0

    source_id = upsert_source(
        conn,
        source_key="agents_levels",
        source_type="agents",
        path=str(AGENTS_LEVELS_PATH),
        meta={"origin": "ai/memory/people/agents_levels.json"},
    )

    agents: Dict[str, Dict[str, Any]] = {}

    if isinstance(data.get("agents"), dict):
        for key, info in data["agents"].items():
            if isinstance(info, dict):
                agents[key] = info
    else:
        for key, info in data.items():
            if key == "meta":
                continue
            if isinstance(info, dict):
                agents[key] = info

    count = 0
    for agent_id, info in agents.items():
        name = info.get("name") or info.get("id") or agent_id
        display_name = (
            info.get("display_name")
            or info.get("arabic_name")
            or info.get("label")
            or name
        )
        family = info.get("family") or info.get("cluster") or info.get("group") or "N/A"
        level = info.get("level") or info.get("rank") or "unknown"
        salary_index = info.get("salary_index") or info.get("salary_score")

        success_rate = info.get("success_rate")
        if success_rate is None:
            rs = info.get("runs_success")
            rt = info.get("runs_total")
            if isinstance(rs, (int, float)) and isinstance(rt, (int, float)) and rt > 0:
                success_rate = float(rs) / float(rt)

        runs_total = info.get("runs_total")
        runs_success = info.get("runs_success")
        runs_failed = info.get("runs_failed")

        body_lines = []
        body_lines.append(f"family={family}")
        body_lines.append(f"level={level}")
        body_lines.append(f"salary_index={salary_index}")
        body_lines.append(f"success_rate={success_rate}")
        body_lines.append(f"runs_total={runs_total}")
        body_lines.append(f"runs_success={runs_success}")
        body_lines.append(f"runs_failed={runs_failed}")
        body = "\n".join(body_lines)

        tags = f"agent,{family}"
        importance = 0.5
        if isinstance(success_rate, (int, float)):
            importance = min(max(success_rate, 0.0), 1.0)

        meta = {
            "agent_id": agent_id,
            "family": family,
            "level": level,
            "salary_index": salary_index,
            "success_rate": success_rate,
            "runs_total": runs_total,
            "runs_success": runs_success,
            "runs_failed": runs_failed,
        }

        upsert_item(
            conn,
            source_id=source_id,
            item_type="agent_level",
            item_key=agent_id,
            title=f"Agent {display_name} ({agent_id}) level & performance",
            body=body,
            importance=importance,
            tags=tags,
            meta=meta,
        )
        count += 1

    return count


def spider_insights(conn: sqlite3.Connection) -> int:
    data = load_json(INSIGHTS_PATH)
    if not isinstance(data, dict):
        print(f"ℹ️ لا يمكن قراءة insights من {INSIGHTS_PATH}")
        return 0

    source_id = upsert_source(
        conn,
        source_key="insights",
        source_type="insight",
        path=str(INSIGHTS_PATH),
        meta={"origin": "ai/memory/insights.json"},
    )

    items = data.get("insights") or data.get("items") or []
    if isinstance(items, dict):
        items = [{"id": k, **v} for k, v in items.items() if isinstance(v, dict)]

    count = 0
    for idx, it in enumerate(items, start=1):
        if not isinstance(it, dict):
            continue
        key = str(it.get("id") or f"insight_{idx}")
        title = it.get("title") or it.get("name") or f"Insight {idx}"
        text = it.get("text") or it.get("description") or ""
        score = it.get("score")
        importance = float(score) if isinstance(score, (int, float)) else 0.6

        tags = "insight"
        meta = {"raw": it}
        upsert_item(
            conn,
            source_id=source_id,
            item_type="insight",
            item_key=key,
            title=title,
            body=text,
            importance=importance,
            tags=tags,
            meta=meta,
        )
        count += 1

    return count


def main() -> None:
    print(f"📁 ROOT        : {ROOT}")
    print(f"📂 KNOWLEDGE   : {KNOWLEDGE_DIR}")
    print(f"🗄  DB         : {DB_PATH}")
    conn = init_db()

    total_items = 0
    total_items += spider_kpis(conn)
    total_items += spider_lessons(conn)
    total_items += spider_curriculum(conn)
    total_items += spider_agents_levels(conn)
    total_items += spider_insights(conn)

    conn.commit()
    conn.close()

    print("----------------------------------------")
    print(f"✅ انتهى سبيدر المعرفة. تم تسجيل {total_items} عنصر معرفة في قاعدة البيانات.")
    print("   - يمكنك لاحقًا بناء واجهة استعلام أو Dashboard فوق data/knowledge/knowledge.db")


if __name__ == "__main__":
    main()
