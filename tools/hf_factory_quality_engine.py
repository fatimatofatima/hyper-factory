#!/usr/bin/env python3
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "factory" / "factory.db"


def get_conn():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def refresh_agent_stats():
    conn = get_conn()
    cur = conn.cursor()

    # تجميع الإحصائيات من task_assignments
    cur.execute(
        """
        SELECT
          agent_id,
          COUNT(*) AS total_runs,
          SUM(CASE WHEN LOWER(COALESCE(result_status, '')) = 'success' THEN 1 ELSE 0 END) AS success_runs,
          SUM(CASE WHEN LOWER(COALESCE(result_status, '')) = 'failed'  THEN 1 ELSE 0 END) AS failed_runs
        FROM task_assignments
        GROUP BY agent_id
        """
    )
    rows = cur.fetchall()

    if not rows:
        print("ℹ️ لا توجد تعيينات في task_assignments – لا يوجد ما يُحدَّث.")
        conn.close()
        return

    print("📊 تحديث أداء العمال من task_assignments → agents:")
    for row in rows:
        agent_id = row["agent_id"]
        total_runs = row["total_runs"] or 0
        success_runs = row["success_runs"] or 0
        failed_runs = row["failed_runs"] or 0
        success_rate = float(success_runs) / total_runs if total_runs else 0.0

        cur.execute(
            """
            UPDATE agents
               SET total_runs   = ?,
                   success_runs = ?,
                   failed_runs  = ?,
                   success_rate = ?
             WHERE id = ?
            """,
            (total_runs, success_runs, failed_runs, success_rate, agent_id),
        )

        print(
            f"  • {agent_id}: total={total_runs}, success={success_runs}, "
            f"failed={failed_runs}, rate={success_rate:.2f}"
        )

    conn.commit()
    conn.close()
    print("✅ تم تحديث إحصائيات الأداء في جدول agents.")
    

def main():
    refresh_agent_stats()


if __name__ == "__main__":
    main()
