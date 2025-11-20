#!/usr/bin/env python3
import sqlite3
from pathlib import Path
from datetime import datetime
import yaml
import argparse
import sys

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "factory" / "factory.db"
RULES_YAML = ROOT / "config" / "skills_task_rules.yaml"


def get_conn():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def load_rules():
    if not RULES_YAML.exists():
        print(f"⚠️ ملف قواعد المهارات غير موجود: {RULES_YAML}")
        return {"default_user": None, "task_type_rules": {}}

    with RULES_YAML.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    default_user = data.get("default_user")
    task_rules = data.get("task_type_rules") or {}
    return {"default_user": default_user, "task_type_rules": task_rules}


def tasks_has_user_id(conn):
    cur = conn.cursor()
    cur.execute("PRAGMA table_info(tasks)")
    cols = [r[1] for r in cur.fetchall()]
    return "user_id" in cols


def infer_user_id(task_row, default_user, has_user_col):
    if has_user_col:
        try:
            uid = task_row["user_id"]
        except KeyError:
            uid = None
        if uid:
            return uid

    try:
        source = task_row["source"] or ""
    except KeyError:
        source = ""

    if source.startswith("user:") and len(source) > 5:
        return source[5:]

    return default_user


def apply_skill_update(conn, user_id, skill_id, delta):
    if not skill_id or delta == 0:
        return

    cur = conn.cursor()
    cur.execute("SELECT level_min, level_max FROM skills WHERE id = ?", (skill_id,))
    row = cur.fetchone()
    if not row:
        print(f"⚠️ المهارة غير معرّفة في جدول skills: {skill_id}")
        return

    level_min = row["level_min"] if row["level_min"] is not None else 0
    level_max = row["level_max"] if row["level_max"] is not None else 100

    cur.execute(
        "SELECT level FROM user_skills WHERE user_id = ? AND skill_id = ?",
        (user_id, skill_id),
    )
    row = cur.fetchone()
    current = row["level"] if row else level_min

    new_level = current + int(delta)
    if new_level < level_min:
        new_level = level_min
    if new_level > level_max:
        new_level = level_max

    now = datetime.now().isoformat(timespec="seconds")
    cur.execute(
        """
        INSERT INTO user_skills (user_id, skill_id, level, last_update)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(user_id, skill_id)
        DO UPDATE SET level = excluded.level,
                      last_update = excluded.last_update
        """,
        (user_id, skill_id, new_level, now),
    )

    print(f"  • تحديث مهارة {skill_id} للمستخدم {user_id}: {current} → {new_level}")


def get_track_default_phase(cur, track_id):
    cur.execute(
        "SELECT name FROM track_phases WHERE track_id = ? ORDER BY phase_order LIMIT 1",
        (track_id,),
    )
    row = cur.fetchone()
    return row["name"] if row else None


def apply_track_update(conn, user_id, track_id, delta_progress):
    if not track_id or delta_progress == 0:
        return

    cur = conn.cursor()
    cur.execute("SELECT id FROM tracks WHERE id = ?", (track_id,))
    if not cur.fetchone():
        print(f"⚠️ المسار غير معرّف في جدول tracks: {track_id}")
        return

    cur.execute(
        "SELECT current_phase, progress FROM user_tracks WHERE user_id = ? AND track_id = ?",
        (user_id, track_id),
    )
    row = cur.fetchone()
    if row:
        current_phase = row["current_phase"]
        current_progress = row["progress"] if row["progress"] is not None else 0.0
    else:
        current_phase = get_track_default_phase(cur, track_id)
        current_progress = 0.0

    new_progress = float(current_progress) + float(delta_progress)
    if new_progress < 0.0:
        new_progress = 0.0
    if new_progress > 100.0:
        new_progress = 100.0

    now = datetime.now().isoformat(timespec="seconds")
    cur.execute(
        """
        INSERT INTO user_tracks (user_id, track_id, current_phase, progress, last_update)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(user_id, track_id)
        DO UPDATE SET current_phase = COALESCE(excluded.current_phase, user_tracks.current_phase),
                      progress = excluded.progress,
                      last_update = excluded.last_update
        """,
        (user_id, track_id, current_phase, new_progress, now),
    )

    print(
        f"  • تحديث مسار {track_id} للمستخدم {user_id}: {current_progress}% → {new_progress}%"
    )


def sync_from_assignments():
    rules = load_rules()
    default_user = rules["default_user"]
    task_rules = rules["task_type_rules"]

    if not task_rules:
        print("ℹ️ لا توجد قواعد task_type_rules في skills_task_rules.yaml – لا شيء لتحديثه.")
        return

    conn = get_conn()
    has_user_col = tasks_has_user_id(conn)
    cur = conn.cursor()

    query = """
        SELECT
          ta.id AS assignment_id,
          ta.task_id,
          ta.agent_id,
          ta.result_status,
          ta.result_notes,
          t.task_type,
          t.description,
          t.source
        FROM task_assignments ta
        JOIN tasks t ON t.id = ta.task_id
        LEFT JOIN skills_task_sync sts ON sts.assignment_id = ta.id
        WHERE ta.result_status IS NOT NULL
          AND sts.assignment_id IS NULL
        ORDER BY ta.id ASC
    """

    cur.execute(query)
    rows = cur.fetchall()

    if not rows:
        print("ℹ️ لا توجد تعيينات جديدة مناسبة لمزامنة المهارات.")
        conn.close()
        return

    processed = 0
    for row in rows:
        assignment_id = row["assignment_id"]
        task_type = row["task_type"]
        result_status = (row["result_status"] or "").lower()

        if not task_type:
            continue

        rule = task_rules.get(task_type)
        if not rule:
            continue

        if result_status and result_status != "success":
            continue

        user_id = infer_user_id(row, default_user, has_user_col)
        if not user_id:
            print(
                f"⚠️ لم يتمكن النظام من تحديد user_id لتعيين #{assignment_id} – تم التخطي."
            )
            continue

        skill_id = rule.get("skill_id")
        skill_delta = rule.get("skill_delta", 0)
        track_id = rule.get("track_id")
        track_delta = rule.get("track_delta", 0)

        print(
            f"\n🔁 مزامنة تعيين #{assignment_id} (task_type={task_type}, user={user_id})"
        )

        if skill_id and skill_delta:
            apply_skill_update(conn, user_id, skill_id, skill_delta)

        if track_id and track_delta:
            apply_track_update(conn, user_id, track_id, track_delta)

        cur.execute(
            "INSERT INTO skills_task_sync (assignment_id, processed_at) VALUES (?, ?)",
            (assignment_id, datetime.now().isoformat(timespec="seconds")),
        )

        processed += 1

    conn.commit()
    conn.close()
    print(f"\n✅ تمّت مزامنة المهارات من التعيينات. عدد التعيينات المعالجة: {processed}")


def main():
    parser = argparse.ArgumentParser(
        description="Hyper Factory – Skills Auto Update from task_assignments"
    )
    parser.add_argument(
        "command",
        choices=["sync"],
        help="sync: مزامنة user_skills/user_tracks من تعيينات المهام",
    )
    args = parser.parse_args()

    if args.command == "sync":
        sync_from_assignments()
    else:
        print("❌ أمر غير مدعوم.")
        sys.exit(1)


if __name__ == "__main__":
    main()
