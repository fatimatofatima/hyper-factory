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
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def recompute_agent_stats():
    conn = get_conn()
    cur = conn.cursor()

    cur.execute(
        """
        SELECT agent_id, result_status
        FROM task_assignments
        WHERE result_status IN ('success','fail')
        """
    )
    rows = cur.fetchall()

    stats = {}
    for row in rows:
        agent_id = row["agent_id"]
        status = row["result_status"]
        if not agent_id:
            continue
        if agent_id not in stats:
            stats[agent_id] = {"success": 0, "fail": 0}
        if status == "success":
            stats[agent_id]["success"] += 1
        elif status == "fail":
            stats[agent_id]["fail"] += 1

    for agent_id, s in stats.items():
        success_runs = s["success"]
        failed_runs = s["fail"]
        total_runs = success_runs + failed_runs
        success_rate = (success_runs / total_runs) if total_runs > 0 else 0.0

        cur.execute(
            """
            UPDATE agents
            SET success_runs = ?,
                failed_runs = ?,
                total_runs = ?,
                success_rate = ?
            WHERE id = ?
            """,
            (success_runs, failed_runs, total_runs, success_rate, agent_id),
        )

    conn.commit()
    conn.close()

    print("✅ تم إعادة حساب إحصائيات العمال من task_assignments.")
    if not stats:
        print("ℹ️ لا توجد أي نتائج (success/fail) حتى الآن.")


def mark_result(task_id: int, result_status: str, notes: str):
    result_status = result_status.lower().strip()
    if result_status not in ("success", "fail"):
        print("⚠️ result_status يجب أن يكون success أو fail.")
        sys.exit(1)

    now = datetime.now().isoformat(timespec="seconds")
    conn = get_conn()
    cur = conn.cursor()

    cur.execute("SELECT id, status FROM tasks WHERE id = ?", (task_id,))
    task = cur.fetchone()
    if not task:
        print(f"⚠️ لا توجد مهمة برقم {task_id} في جدول tasks.")
        conn.close()
        sys.exit(1)

    cur.execute(
        """
        SELECT id, agent_id
        FROM task_assignments
        WHERE task_id = ?
        ORDER BY id DESC
        LIMIT 1
        """,
        (task_id,),
    )
    assign = cur.fetchone()
    if not assign:
        print(f"⚠️ لا يوجد تعيين (task_assignments) للمهمة #{task_id}.")
        conn.close()
        sys.exit(1)

    assign_id = assign["id"]
    agent_id = assign["agent_id"]

    new_task_status = "done" if result_status == "success" else "failed"

    cur.execute(
        "UPDATE tasks SET status = ? WHERE id = ?",
        (new_task_status, task_id),
    )

    cur.execute(
        """
        UPDATE task_assignments
        SET result_status = ?, result_notes = ?, completed_at = ?
        WHERE id = ?
        """,
        (result_status, notes, now, assign_id),
    )

    conn.commit()
    conn.close()

    print("✅ تم تسجيل نتيجة المهمة:")
    print(f"   task_id   : {task_id}")
    print(f"   agent_id  : {agent_id}")
    print(f"   status    : {result_status}")
    if notes:
        print(f"   notes     : {notes}")


def show_agents(agent_id: str = None):
    conn = get_conn()
    cur = conn.cursor()

    if agent_id:
        cur.execute(
            """
            SELECT id, display_name, family, role, level,
                   COALESCE(total_runs,0) AS total_runs,
                   COALESCE(success_runs,0) AS success_runs,
                   COALESCE(failed_runs,0) AS failed_runs,
                   COALESCE(success_rate,0.0) AS success_rate
            FROM agents
            WHERE id = ?
            """,
            (agent_id,),
        )
        rows = cur.fetchall()
    else:
        cur.execute(
            """
            SELECT id, display_name, family, role, level,
                   COALESCE(total_runs,0) AS total_runs,
                   COALESCE(success_runs,0) AS success_runs,
                   COALESCE(failed_runs,0) AS failed_runs,
                   COALESCE(success_rate,0.0) AS success_rate
            FROM agents
            ORDER BY success_rate DESC, total_runs DESC, id
            """
        )
        rows = cur.fetchall()

    conn.close()

    if not rows:
        if agent_id:
            print(f"⚠️ لا يوجد عامل بالمعرّف: {agent_id}")
        else:
            print("ℹ️ لا يوجد أي عمال في جدول agents.")
        return

    print("📊 إحصائيات العمال:")
    print(
        "  {0:<18} {1:<16} {2:<10} {3:<16} {4:<8} {5:<8} {6:<8} {7:<8}".format(
            "id",
            "name",
            "family",
            "role",
            "runs",
            "success",
            "fail",
            "succ%"
        )
    )
    print("  " + "-" * 90)
    for r in rows:
        succ_rate_pct = float(r["success_rate"]) * 100.0
        print(
            "  {0:<18} {1:<16} {2:<10} {3:<16} {4:<8} {5:<8} {6:<8} {7:<7.2f}".format(
                r["id"] or "",
                (r["display_name"] or "")[:15],
                (r["family"] or "")[:9],
                (r["role"] or "")[:15],
                r["total_runs"],
                r["success_runs"],
                r["failed_runs"],
                succ_rate_pct,
            )
        )


def main():
    parser = argparse.ArgumentParser(description="Hyper Factory – Results & Quality Engine")
    sub = parser.add_subparsers(dest="command", required=True)

    p_mark = sub.add_parser("set-result", help="تسجيل نتيجة مهمة (success/fail)")
    p_mark.add_argument("task_id", type=int)
    p_mark.add_argument("result_status", choices=["success", "fail"])
    p_mark.add_argument("notes", nargs="*", help="ملاحظات اختيارية")

    sub.add_parser("recompute-agents", help="إعادة حساب إحصائيات جميع العمال")

    p_show = sub.add_parser("show-agents", help="عرض إحصائيات العمال")
    p_show.add_argument("agent_id", nargs="?", default=None)

    args = parser.parse_args()

    if args.command == "set-result":
        notes = " ".join(args.notes) if args.notes else ""
        mark_result(args.task_id, args.result_status, notes)
        # بعد كل تسجيل نتيجة نعيد حساب أداء العمال
        recompute_agent_stats()
    elif args.command == "recompute-agents":
        recompute_agent_stats()
    elif args.command == "show-agents":
        show_agents(args.agent_id)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
