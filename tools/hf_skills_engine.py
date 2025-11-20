#!/usr/bin/env python3
import sqlite3
from pathlib import Path
from datetime import datetime
import yaml
import argparse
import sys

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "factory" / "factory.db"
SKILLS_YAML = ROOT / "config" / "skills_tracks_backend_complete.yaml"


def get_conn():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    return sqlite3.connect(DB_PATH)


def init_skills_from_yaml():
    if not SKILLS_YAML.exists():
        print(f"⚠️ ملف المهارات غير موجود: {SKILLS_YAML}")
        return

    with SKILLS_YAML.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    skills = data.get("skills", {})
    tracks = data.get("tracks", {})

    conn = get_conn()
    cur = conn.cursor()

    for skill_id, s in skills.items():
        cur.execute(
            """
            INSERT OR REPLACE INTO skills
            (id, name, category, level_min, level_max, description)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                skill_id,
                s.get("name"),
                s.get("category"),
                int(s.get("level_min", 0)),
                int(s.get("level_max", 100)),
                s.get("description"),
            ),
        )

    for track_id, t in tracks.items():
        cur.execute(
            """
            INSERT OR REPLACE INTO tracks
            (id, name, description) VALUES (?, ?, ?)
            """,
            (track_id, t.get("name"), t.get("description")),
        )
        phases = t.get("phases", [])
        cur.execute("DELETE FROM track_phases WHERE track_id = ?", (track_id,))
        for i, ph in enumerate(phases, start=1):
            phase_name = ph.get("phase") or ph.get("name") or f"Phase {i}"
            cur.execute(
                """
                INSERT INTO track_phases (track_id, phase_order, name)
                VALUES (?, ?, ?)
                """,
                (track_id, i, phase_name),
            )

    conn.commit()
    conn.close()
    print(f"✅ تم تحميل {len(skills)} مهارة و {len(tracks)} مسار من {SKILLS_YAML}.")


def set_user_skill_level(user_id: str, skill_id: str, level: int):
    now = datetime.now().isoformat(timespec="seconds")
    conn = get_conn()
    cur = conn.cursor()

    cur.execute("SELECT id FROM skills WHERE id = ?", (skill_id,))
    if not cur.fetchone():
        print(f"⚠️ المهارة غير معرّفة في جدول skills: {skill_id}")
        conn.close()
        return

    cur.execute(
        """
        INSERT INTO user_skills (user_id, skill_id, level, last_update)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(user_id, skill_id)
        DO UPDATE SET level = excluded.level, last_update = excluded.last_update
        """,
        (user_id, skill_id, level, now),
    )
    conn.commit()
    conn.close()
    print(f"✅ تم ضبط مستوى المهارة {skill_id} للمستخدم {user_id} إلى {level}.")


def set_user_track(user_id: str, track_id: str, current_phase: str, progress: float):
    now = datetime.now().isoformat(timespec="seconds")
    conn = get_conn()
    cur = conn.cursor()

    cur.execute("SELECT id FROM tracks WHERE id = ?", (track_id,))
    if not cur.fetchone():
        print(f"⚠️ المسار غير معرّف في جدول tracks: {track_id}")
        conn.close()
        return

    cur.execute(
        """
        INSERT INTO user_tracks (user_id, track_id, current_phase, progress, last_update)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(user_id, track_id)
        DO UPDATE SET current_phase = excluded.current_phase,
                      progress = excluded.progress,
                      last_update = excluded.last_update
        """,
        (user_id, track_id, current_phase, progress, now),
    )
    conn.commit()
    conn.close()
    print(f"✅ تم تحديث مسار المستخدم {user_id} على المسار {track_id} ({progress}%).")


def show_user(user_id: str):
    conn = get_conn()
    cur = conn.cursor()

    print(f"📊 تقرير مهارات المستخدم: {user_id}")
    print("----- المهارات -----")
    cur.execute(
        """
        SELECT us.skill_id, s.name, us.level, us.last_update
        FROM user_skills us
        LEFT JOIN skills s ON s.id = us.skill_id
        WHERE us.user_id = ?
        ORDER BY us.skill_id
        """,
        (user_id,),
    )
    rows = cur.fetchall()
    if not rows:
        print("  (لا توجد مهارات مسجلة)")
    else:
        for sid, name, lvl, lu in rows:
            print(f"  - {sid} ({name}): level={lvl} @ {lu}")

    print("----- المسارات -----")
    cur.execute(
        """
        SELECT ut.track_id, t.name, ut.current_phase, ut.progress, ut.last_update
        FROM user_tracks ut
        LEFT JOIN tracks t ON t.id = ut.track_id
        WHERE ut.user_id = ?
        ORDER BY ut.track_id
        """,
        (user_id,),
    )
    rows = cur.fetchall()
    if not rows:
        print("  (لا توجد مسارات مسجلة)")
    else:
        for tid, name, phase, prog, lu in rows:
            print(f"  - {tid} ({name}): phase={phase}, progress={prog}% @ {lu}")

    conn.close()


def main():
    parser = argparse.ArgumentParser(description="Hyper Factory Skills Engine")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("init-skills", help="تحميل تعريف المهارات والمسارات من YAML إلى قاعدة البيانات")

    p_set_skill = sub.add_parser("set-skill", help="ضبط مستوى مهارة لمستخدم")
    p_set_skill.add_argument("user_id")
    p_set_skill.add_argument("skill_id")
    p_set_skill.add_argument("level", type=int)

    p_set_track = sub.add_parser("set-track", help="تحديث مسار مستخدم")
    p_set_track.add_argument("user_id")
    p_set_track.add_argument("track_id")
    p_set_track.add_argument("current_phase")
    p_set_track.add_argument("progress", type=float)

    p_show = sub.add_parser("show-user", help="عرض تقرير مهارات ومسارات مستخدم")
    p_show.add_argument("user_id")

    args = parser.parse_args()

    if args.command == "init-skills":
        init_skills_from_yaml()
    elif args.command == "set-skill":
        set_user_skill_level(args.user_id, args.skill_id, args.level)
    elif args.command == "set-track":
        set_user_track(args.user_id, args.track_id, args.current_phase, args.progress)
    elif args.command == "show-user":
        show_user(args.user_id)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
