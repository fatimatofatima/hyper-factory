#!/usr/bin/env python3
import sqlite3
from pathlib import Path
from datetime import datetime, date
import argparse
import sys
import json

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "factory" / "factory.db"
REPORTS_DIR = ROOT / "reports" / "factory" / "daily"


def get_conn():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    return sqlite3.connect(DB_PATH)


def ensure_daily_table(conn):
    cur = conn.cursor()
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS daily_reports (
          day TEXT PRIMARY KEY,
          created_at TEXT NOT NULL,
          total_tasks INTEGER,
          tasks_done INTEGER,
          tasks_failed INTEGER,
          tasks_assigned INTEGER,
          tasks_queued INTEGER,
          total_agents INTEGER,
          avg_success_rate REAL,
          top_agent_id TEXT,
          top_agent_success_rate REAL,
          notes TEXT
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
    return None


def collect_today_metrics(conn, day: str):
    cur = conn.cursor()

    # توزيع حالات المهام لـ "اليوم"
    cur.execute(
        """
        SELECT status, COUNT(*) FROM tasks
        WHERE substr(created_at,1,10) = ?
        GROUP BY status;
        """,
        (day,),
    )
    status_counts = {row[0]: row[1] for row in cur.fetchall()}

    tasks_done = status_counts.get("done", 0)
    tasks_failed = status_counts.get("failed", 0)
    tasks_assigned = status_counts.get("assigned", 0)
    tasks_queued = status_counts.get("queued", 0)
    total_tasks = tasks_done + tasks_failed + tasks_assigned + tasks_queued

    # ملخص العمال
    cur.execute(
        "SELECT COUNT(*), AVG(COALESCE(success_rate,0.0)) FROM agents;"
    )
    row = cur.fetchone()
    total_agents = row[0] if row and row[0] is not None else 0
    avg_success_rate = row[1] if row and row[1] is not None else 0.0

    cur.execute(
        """
        SELECT id, success_rate, total_runs
        FROM agents
        ORDER BY success_rate DESC, total_runs DESC
        LIMIT 1;
        """
    )
    row = cur.fetchone()
    if row:
        top_agent_id = row[0]
        top_agent_success_rate = row[1] if row[1] is not None else 0.0
    else:
        top_agent_id = None
        top_agent_success_rate = 0.0

    return {
        "total_tasks": total_tasks,
        "tasks_done": tasks_done,
        "tasks_failed": tasks_failed,
        "tasks_assigned": tasks_assigned,
        "tasks_queued": tasks_queued,
        "total_agents": total_agents,
        "avg_success_rate": avg_success_rate,
        "top_agent_id": top_agent_id,
        "top_agent_success_rate": top_agent_success_rate,
    }


def build_training_tasks(conn, day: str):
    """
    يبني مهام تدريب/اختبار يومية بناء على نتائج التعلم في learning_log
    لكل agent/task_type حيث الفشل >= النجاح.
    """
    cur = conn.cursor()

    # لو جدول التعلم مش موجود، تخطى بهدوء
    cur.execute(
        """
        SELECT name FROM sqlite_master WHERE type='table' AND name='learning_log';
        """
    )
    if not cur.fetchone():
        print("ℹ️ جدول learning_log غير موجود – تخطى مرحلة بناء التدريب.")
        return []

    cur.execute(
        """
        SELECT
          agent_id,
          task_type,
          SUM(CASE WHEN result_status='success' THEN 1 ELSE 0 END) AS ok_cnt,
          SUM(CASE WHEN result_status='failed' THEN 1 ELSE 0 END) AS fail_cnt
        FROM learning_log
        WHERE substr(applied_at,1,10) = ?
        GROUP BY agent_id, task_type
        HAVING fail_cnt > 0;
        """,
        (day,),
    )
    rows = cur.fetchall()
    if not rows:
        print("ℹ️ لا توجد فشل في learning_log لليوم – لا مهام تدريب إضافية.")
        return []

    now_iso = datetime.now().isoformat(timespec="seconds")
    created = []
    max_tasks = 10  # حد أقصى لعدد مهام التدريب اليومية (مراعاة المساحة والضجيج)
    count = 0

    for agent_id, task_type, ok_cnt, fail_cnt in rows:
        if count >= max_tasks:
            break

        skill_id = resolve_skill_id(task_type)
        desc_prefix = f"تدريب يومي للـ agent {agent_id}"
        desc = (
            f"{desc_prefix} على مهمة نوعها {task_type or 'عام'}"
            f" (نجاح={ok_cnt}, فشل={fail_cnt}"
        )
        if skill_id:
            desc += f", skill={skill_id}"
        desc += ")."

        # تجنب تكرار نفس التدريب في نفس اليوم
        cur.execute(
            """
            SELECT COUNT(*) FROM tasks
            WHERE source='daily_trainer'
              AND substr(created_at,1,10)=?
              AND description LIKE ?;
            """,
            (day, desc_prefix + "%"),
        )
        exists = cur.fetchone()[0]
        if exists:
            continue

        cur.execute(
            """
            INSERT INTO tasks (created_at, source, description, task_type, priority, status)
            VALUES (?, 'daily_trainer', ?, 'coaching', 'normal', 'queued');
            """,
            (now_iso, desc),
        )
        created.append(
            {
                "agent_id": agent_id,
                "task_type": task_type,
                "skill_id": skill_id,
                "ok": ok_cnt,
                "fail": fail_cnt,
                "description": desc,
            }
        )
        count += 1

    conn.commit()
    print(f"📚 تم إنشاء {len(created)} مهام تدريب/اختبار يومية.")
    return created


def write_reports(day: str, created_at: str, metrics: dict, trainings: list):
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    base_name = f"factory_daily_{day}"
    txt_path = REPORTS_DIR / f"{base_name}.txt"
    json_path = REPORTS_DIR / f"{base_name}.json"

    # JSON صغير
    data = {
        "day": day,
        "created_at": created_at,
        "metrics": metrics,
        "trainings": trainings,
    }
    with json_path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    # تقرير نصي صغير
    lines = []
    lines.append("Hyper Factory – Daily Knowledge & Quality Report")
    lines.append("================================================")
    lines.append(f"Day       : {day}")
    lines.append(f"Created   : {created_at}")
    lines.append("")
    lines.append("Tasks Summary (today):")
    lines.append(f"  total      : {metrics['total_tasks']}")
    lines.append(f"  done       : {metrics['tasks_done']}")
    lines.append(f"  failed     : {metrics['tasks_failed']}")
    lines.append(f"  assigned   : {metrics['tasks_assigned']}")
    lines.append(f"  queued     : {metrics['tasks_queued']}")
    lines.append("")
    lines.append("Agents Performance:")
    lines.append(f"  total_agents        : {metrics['total_agents']}")
    lines.append(f"  avg_success_rate    : {metrics['avg_success_rate']:.3f}")
    if metrics["top_agent_id"]:
        lines.append(
            f"  top_agent           : {metrics['top_agent_id']} "
            f"(success_rate={metrics['top_agent_success_rate']:.3f})"
        )
    else:
        lines.append("  top_agent           : N/A")
    lines.append("")
    lines.append("Training / Self-Tests Created:")
    if trainings:
        for t in trainings:
            lines.append(
                f"  - agent={t['agent_id']}, type={t['task_type']}, "
                f"skill={t['skill_id']}, ok={t['ok']}, fail={t['fail']}"
            )
    else:
        lines.append("  (no new training tasks today)")

    with txt_path.open("w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    return str(txt_path), str(json_path)


def store_daily_row(conn, day: str, created_at: str, metrics: dict, trainings: list):
    ensure_daily_table(conn)
    cur = conn.cursor()
    notes = f"training_tasks={len(trainings)}"
    cur.execute(
        """
        INSERT INTO daily_reports
        (day, created_at, total_tasks, tasks_done, tasks_failed,
         tasks_assigned, tasks_queued, total_agents, avg_success_rate,
         top_agent_id, top_agent_success_rate, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(day) DO UPDATE SET
          created_at = excluded.created_at,
          total_tasks = excluded.total_tasks,
          tasks_done = excluded.tasks_done,
          tasks_failed = excluded.tasks_failed,
          tasks_assigned = excluded.tasks_assigned,
          tasks_queued = excluded.tasks_queued,
          total_agents = excluded.total_agents,
          avg_success_rate = excluded.avg_success_rate,
          top_agent_id = excluded.top_agent_id,
          top_agent_success_rate = excluded.top_agent_success_rate,
          notes = excluded.notes;
        """,
        (
            day,
            created_at,
            metrics["total_tasks"],
            metrics["tasks_done"],
            metrics["tasks_failed"],
            metrics["tasks_assigned"],
            metrics["tasks_queued"],
            metrics["total_agents"],
            metrics["avg_success_rate"],
            metrics["top_agent_id"],
            metrics["top_agent_success_rate"],
            notes,
        ),
    )
    conn.commit()


def run_daily():
    if not DB_PATH.exists():
        print(f"❌ قاعدة بيانات المصنع غير موجودة: {DB_PATH}")
        print("   شغّل: ./hf_factory_cli.sh init-db")
        return

    today = date.today().isoformat()
    created_at = datetime.now().isoformat(timespec="seconds")

    conn = get_conn()
    conn.row_factory = sqlite3.Row

    metrics = collect_today_metrics(conn, today)
    trainings = build_training_tasks(conn, today)
    store_daily_row(conn, today, created_at, metrics, trainings)
    txt_path, json_path = write_reports(today, created_at, metrics, trainings)

    conn.close()

    print("")
    print("📊 Daily Knowledge & Quality Summary:")
    print(f"  day           : {today}")
    print(f"  total_tasks   : {metrics['total_tasks']}")
    print(f"  done          : {metrics['tasks_done']}")
    print(f"  failed        : {metrics['tasks_failed']}")
    print(f"  assigned      : {metrics['tasks_assigned']}")
    print(f"  queued        : {metrics['tasks_queued']}")
    print(f"  total_agents  : {metrics['total_agents']}")
    print(f"  avg_success   : {metrics['avg_success_rate']:.3f}")
    print(f"  top_agent     : {metrics['top_agent_id']}")
    print(f"  report_txt    : {txt_path}")
    print(f"  report_json   : {json_path}")
    print(f"  training_new  : {len(trainings)}")
    print("✅ Daily report completed.")


def main():
    parser = argparse.ArgumentParser(description="Hyper Factory – Daily Knowledge & Quality Report")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("run", help="تشغيل مراجعة يومية + بناء مهام تدريب/اختبارات")

    args = parser.parse_args()
    if args.command == "run":
        run_daily()
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
