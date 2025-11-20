#!/usr/bin/env python3
import sqlite3
from pathlib import Path
from datetime import datetime
import argparse
import sys

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "factory" / "factory.db"


def get_conn():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    return sqlite3.connect(DB_PATH)


def ensure_learning_log(conn):
    cur = conn.cursor()
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS learning_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          assignment_id INTEGER UNIQUE,
          agent_id TEXT,
          task_id INTEGER,
          task_type TEXT,
          result_status TEXT,
          applied_at TEXT,
          delta REAL,
          skill_id TEXT,
          user_id TEXT,
          note TEXT
        );
        """
    )
    conn.commit()


def resolve_skill_id(task_type: str) -> str | None:
    t = (task_type or "").lower()
    if t == "debug":
        return "debug_skills"
    if t == "architecture":
        return "system_architecture"
    if t == "coaching":
        return "teaching_skills"
    if t == "knowledge":
        return "knowledge_research"
    # يمكن إضافة mappings أخرى لاحقًا
    return None


def apply_learning():
    if not DB_PATH.exists():
        print(f"⚠️ قاعدة البيانات غير موجودة: {DB_PATH}")
        print("   شغّل: ./hf_factory_cli.sh init-db")
        return

    conn = get_conn()
    conn.row_factory = sqlite3.Row
    ensure_learning_log(conn)
    cur = conn.cursor()

    # assignments التى لها result_status ولم تُستخدم فى learning_log
    cur.execute(
        """
        SELECT
          ta.id AS assignment_id,
          ta.agent_id,
          ta.task_id,
          ta.result_status,
          ta.result_notes,
          t.task_type
        FROM task_assignments ta
        JOIN tasks t ON t.id = ta.task_id
        LEFT JOIN learning_log ll ON ll.assignment_id = ta.id
        WHERE ta.result_status IS NOT NULL
          AND ll.assignment_id IS NULL
        ORDER BY ta.id ASC;
        """
    )
    rows = cur.fetchall()
    if not rows:
        print("ℹ️ لا توجد تعيينات جديدة لتطبيق التعلم عليها.")
        conn.close()
        return

    print(f"🧠 بدء تطبيق التعلم على {len(rows)} تعيين/مهمة...")
    updated_agents = 0
    updated_skills = 0

    for r in rows:
        assignment_id = r["assignment_id"]
        agent_id = r["agent_id"]
        task_id = r["task_id"]
        result_status = (r["result_status"] or "").lower()
        task_type = r["task_type"]
        note = r["result_notes"] or ""

        if not agent_id:
            print(f"  • تعيين {assignment_id}: لا يوجد agent_id – تخطى.")
            continue

        # تحديث counters فى agents
        cur.execute(
            """
            SELECT success_runs, failed_runs, total_runs
            FROM agents WHERE id = ?;
            """,
            (agent_id,),
        )
        row_agent = cur.fetchone()
        if not row_agent:
            print(f"  • تعيين {assignment_id}: agent {agent_id} غير موجود فى agents – تخطى.")
            continue

        success_runs = row_agent["success_runs"] or 0
        failed_runs = row_agent["failed_runs"] or 0
        total_runs = row_agent["total_runs"] or 0

        total_runs += 1
        delta_success = 0.0
        if result_status == "success":
            success_runs += 1
            delta_success = 1.0
        else:
            failed_runs += 1

        success_rate = success_runs / total_runs if total_runs > 0 else 0.0

        cur.execute(
            """
            UPDATE agents
            SET success_runs = ?, failed_runs = ?, total_runs = ?, success_rate = ?
            WHERE id = ?;
            """,
            (success_runs, failed_runs, total_runs, success_rate, agent_id),
        )
        updated_agents += 1

        # تحديث skill للمستخدم/العامل (user_id = agent_id) إن أمكن
        skill_id = resolve_skill_id(task_type)
        delta_skill = 0.0
        user_id = agent_id

        if skill_id and result_status in ("success", "failed"):
            # تأكد أن skill موجودة فى جدول skills
            cur.execute("SELECT COUNT(*) FROM skills WHERE id = ?;", (skill_id,))
            exists_skill = cur.fetchone()[0]
            if exists_skill == 0:
                print(
                    f"  • تعيين {assignment_id}: skill {skill_id} غير موجودة فى جدول skills – تخطى تحديث skill."
                )
            else:
                # اقرأ المستوى الحالى من user_skills
                cur.execute(
                    """
                    SELECT level FROM user_skills
                    WHERE user_id = ? AND skill_id = ?;
                    """,
                    (user_id, skill_id),
                )
                row_skill = cur.fetchone()
                current_level = row_skill["level"] if row_skill else 0

                if result_status == "success":
                    delta_skill = 5.0
                else:
                    delta_skill = -2.0

                new_level = current_level + delta_skill
                if new_level < 0:
                    new_level = 0
                if new_level > 100:
                    new_level = 100

                now = datetime.now().isoformat(timespec="seconds")
                cur.execute(
                    """
                    INSERT INTO user_skills (user_id, skill_id, level, last_update)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT(user_id, skill_id)
                    DO UPDATE SET level = excluded.level,
                                  last_update = excluded.last_update;
                    """,
                    (user_id, skill_id, new_level, now),
                )
                updated_skills += 1
        else:
            if not skill_id:
                print(
                    f"  • تعيين {assignment_id}: لا يوجد mapping واضح لـ task_type={task_type} – تخطى تحديث skill."
                )

        # تسجيل فى learning_log
        applied_at = datetime.now().isoformat(timespec="seconds")
        cur.execute(
            """
            INSERT INTO learning_log
            (assignment_id, agent_id, task_id, task_type, result_status,
             applied_at, delta, skill_id, user_id, note)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """,
            (
                assignment_id,
                agent_id,
                task_id,
                task_type,
                result_status,
                applied_at,
                delta_skill,
                skill_id,
                user_id,
                note,
            ),
        )

    conn.commit()
    conn.close()

    print("")
    print("📊 ملخص التعلم:")
    print(f"  ▸ تعيينات معالجة   : {len(rows)}")
    print(f"  ▸ وكلاء محدَّثون    : {updated_agents}")
    print(f"  ▸ Skills محدثة      : {updated_skills}")
    print("✅ تطبيق التعلم اكتمل.")


def main():
    parser = argparse.ArgumentParser(description="Hyper Factory – Learning Engine")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("apply", help="تطبيق التعلم على التعيينات ذات result_status")

    args = parser.parse_args()

    if args.command == "apply":
        apply_learning()
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
