#!/usr/bin/env python3
import sqlite3
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "factory" / "factory.db"


DEFAULT_CLONES = {
    "knowledge_spider": 3,   # سبايدر أساسي + 2 إضافيين
    "technical_coach": 3,    # كوتش أساسي + 2 إضافيين
    "analyzer_basic": 3,     # محلل أساسي + 2 إضافيين
    "debug_expert": 2,       # دكتور (debug) + نسخة إضافية
}


def get_conn():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    return sqlite3.connect(DB_PATH)


def clone_agent(conn, base_id: str, count: int):
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, family, role, display_name, level, salary_index, skills
        FROM agents WHERE id = ?;
        """,
        (base_id,),
    )
    row = cur.fetchone()
    if not row:
        print(f"ℹ️ Agent base غير موجود في agents: {base_id}")
        return 0

    _, family, role, display_name, level, salary_index, skills = row
    created = 0

    for i in range(2, count + 1):
        clone_id = f"{base_id}_{i}"
        clone_name = f"{display_name} ({i})" if display_name else f"{base_id} ({i})"

        cur.execute("SELECT COUNT(*) FROM agents WHERE id = ?;", (clone_id,))
        if cur.fetchone()[0] > 0:
            continue

        cur.execute(
            """
            INSERT INTO agents
            (id, family, role, display_name, level, salary_index,
             success_rate, total_runs, success_runs, failed_runs, skills)
            VALUES (?, ?, ?, ?, ?, ?, 0.0, 0, 0, 0, ?);
            """,
            (clone_id, family, role, clone_name, level, salary_index, skills),
        )
        created += 1

    print(f"✅ cloned {created} agents from base={base_id}")
    return created


def ensure_integration_tasks(conn):
    """
    إنشاء مجموعة مهام دمج (Integration) عالية الأولوية
    لربط Hyper Factory مع SmartFriend Suite و FFactory.
    تنشأ مرة واحدة فقط إذا لم تكن موجودة.
    """
    cur = conn.cursor()

    templates = [
        "خطة دمج Hyper Factory مع SmartFriend Suite (قراءة/كتابة للـ DB والـ APIs).",
        "خطة ربط Hyper Factory مع FFactory (خط إنتاج الكود والتشغيل).",
        "تصميم قناة تواصل بين Hyper Factory و SmartFriend/FFactory لمراقبة الجودة والمعرفة.",
    ]

    now_iso = datetime.now().isoformat(timespec="seconds")
    created = 0

    for desc in templates:
        cur.execute(
            """
            SELECT COUNT(*) FROM tasks
            WHERE source='integration_planner' AND description = ?;
            """,
            (desc,),
        )
        if cur.fetchone()[0] > 0:
            continue

        cur.execute(
            """
            INSERT INTO tasks
            (created_at, source, description, task_type, priority, status)
            VALUES (?, 'integration_planner', ?, 'architecture', 'high', 'queued');
            """,
            (now_iso, desc),
        )
        created += 1

    conn.commit()
    print(f"🏗️ integration_planner: created {created} integration tasks.")


def main():
    if not DB_PATH.exists():
        print(f"❌ factory.db غير موجود: {DB_PATH}")
        print("   شغّل أولًا: ./hf_factory_cli.sh init-db")
        return

    conn = get_conn()

    total_cloned = 0
    for base_id, count in DEFAULT_CLONES.items():
        total_cloned += clone_agent(conn, base_id, count)

    ensure_integration_tasks(conn)
    conn.close()

    print("")
    print("📌 Summary:")
    print(f"  cloned_agents_total  : {total_cloned}")
    print("  integration_tasks     : تم فحص/إنشاء مهام دمج أساسية.")
    print("✅ clone & integration planning completed.")


if __name__ == "__main__":
    main()
