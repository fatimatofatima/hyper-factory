#!/usr/bin/env python3
import sqlite3
import json
from datetime import datetime
from pathlib import Path
import argparse
import sys

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "data" / "factory" / "factory.db"
AGENTS_JSON = ROOT / "ai" / "memory" / "people" / "all_agents_complete.json"


def get_conn():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    return sqlite3.connect(DB_PATH)


def init_agents_from_json():
    if not AGENTS_JSON.exists():
        print(f"⚠️ ملف العمال غير موجود: {AGENTS_JSON}")
        return

    with AGENTS_JSON.open("r", encoding="utf-8") as f:
        agents = json.load(f)

    conn = get_conn()
    cur = conn.cursor()

    for a in agents:
        agent_id = a.get("agent")
        if not agent_id:
            continue
        skills = a.get("skills", [])
        cur.execute(
            """
            INSERT OR REPLACE INTO agents
            (id, family, role, display_name, level, salary_index,
             success_rate, total_runs, success_runs, failed_runs, skills)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                agent_id,
                a.get("family"),
                a.get("role"),
                a.get("display_name"),
                a.get("level"),
                float(a.get("salary_index", 1.0)) if a.get("salary_index") is not None else 1.0,
                float(a.get("success_rate", 0.0)) if a.get("success_rate") is not None else 0.0,
                int(a.get("total_runs", 0)),
                int(a.get("success_runs", 0)),
                int(a.get("failed_runs", 0)),
                json.dumps(skills, ensure_ascii=False),
            ),
        )

    conn.commit()
    conn.close()
    print(f"✅ تم تحميل {len(agents)} عامل من {AGENTS_JSON} إلى جدول agents.")


def classify_task(description: str) -> str:
    text = description.lower()
    debug_kw = ["خطأ", "اخطاء", "bug", "error", "traceback", "crash"]
    arch_kw = ["تصميم", "معماري", "architecture", "system design", "دمج", "integration"]
    coach_kw = ["تعلم", "تعليمي", "مسار", "كورسات", "course", "learning", "track", "تدريب", "coaching"]
    know_kw = ["معرفة", "documentation", "docs", "بحث", "research", "spider", "crawler"]
    pipe_kw = ["pipeline", "ingest", "ingestor", "processor", "analyzer", "reporter"]

    if any(k in text for k in debug_kw):
        return "debug"
    if any(k in text for k in arch_kw):
        return "architecture"
    if any(k in text for k in coach_kw):
        return "coaching"
    if any(k in text for k in know_kw):
        return "knowledge"
    if any(k in text for k in pipe_kw):
        return "pipeline"
    return "general"


def new_task(description: str, priority: str = "normal", source: str = "cli"):
    if priority not in ("low", "normal", "high"):
        priority = "normal"
    task_type = classify_task(description)
    created_at = datetime.now().isoformat(timespec="seconds")

    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO tasks (created_at, source, description, task_type, priority, status)
        VALUES (?, ?, ?, ?, ?, 'queued')
        """,
        (created_at, source, description, task_type, priority),
    )
    task_id = cur.lastrowid
    conn.commit()
    conn.close()

    print("✅ تم إنشاء مهمة جديدة:")
    print(f"   id         : {task_id}")
    print(f"   type       : {task_type}")
    print(f"   priority   : {priority}")
    print(f"   desc       : {description}")
    return task_id


def pick_agent_for_task(task_type: str, conn):
    """
    اختيار Agent بناءً على العائلة (family) ثم الأفضلية حسب success_rate ثم total_runs.
    هذا يسمح بوجود أكثر من سبايدر، أكثر من كوتش، أكثر من محلل، إلخ.
    """
    family_map = {
        "debug": "debugging",
        "architecture": "architecture",
        "coaching": "training",
        "knowledge": "knowledge",
        "pipeline": "pipeline",
    }
    family = family_map.get(task_type)

    cur = conn.cursor()

    # أولًا: حاول اختيار أفضل Agent داخل العائلة
    if family:
        cur.execute(
            """
            SELECT id, COALESCE(display_name,''), COALESCE(success_rate,0.0) AS sr,
                   COALESCE(total_runs,0) AS tr
            FROM agents
            WHERE family = ?
            ORDER BY sr DESC, tr DESC
            LIMIT 1;
            """,
            (family,),
        )
        row = cur.fetchone()
        if row:
            return row[0], row[1], row[2], family

    # ثانيًا: fallback على أفضل Agent على مستوى المصنع كاملًا
    cur.execute(
        """
        SELECT id, COALESCE(display_name,''), COALESCE(success_rate,0.0) AS sr,
               COALESCE(total_runs,0) AS tr
        FROM agents
        ORDER BY sr DESC, tr DESC
        LIMIT 1;
        """
    )
    row = cur.fetchone()
    if row:
        return row[0], row[1], row[2], "any"

    return None


def assign_next():
    conn = get_conn()
    cur = conn.cursor()

    cur.execute(
        """
        SELECT id, description, task_type, priority, created_at
        FROM tasks
        WHERE status = 'queued'
        ORDER BY
          CASE priority
            WHEN 'high' THEN 0
            WHEN 'normal' THEN 1
            ELSE 2
          END,
          created_at ASC
        LIMIT 1
        """
    )
    task = cur.fetchone()
    if not task:
        print("ℹ️ لا توجد مهام في حالة queued.")
        conn.close()
        return

    task_id, desc, task_type, priority, created_at = task
    picked = pick_agent_for_task(task_type, conn)
    if not picked:
        print("⚠️ لا يوجد عمال في جدول agents، لا يمكن التوزيع.")
        conn.close()
        return

    agent_id, display_name, success_rate, family = picked
    assigned_at = datetime.now().isoformat(timespec="seconds")
    reason = f"task_type={task_type}, family={family}, priority={priority}, picked_agent={agent_id}"

    cur.execute("UPDATE tasks SET status = 'assigned' WHERE id = ?", (task_id,))
    cur.execute(
        """
        INSERT INTO task_assignments
        (task_id, agent_id, decision_reason, assigned_at, completed_at, result_status)
        VALUES (?, ?, ?, ?, NULL, NULL)
        """,
        (task_id, agent_id, reason, assigned_at),
    )
    conn.commit()
    conn.close()

    print("✅ تم إسناد مهمة:")
    print(f"   task_id    : {task_id}")
    print(f"   type       : {task_type}")
    print(f"   family     : {family}")
    print(f"   priority   : {priority}")
    print(f"   agent      : {agent_id} ({display_name})")
    print(f"   reason     : {reason}")
    print("")

    # أمر التنفيذ المقترح – يظل كما هو، لكن الآن ممكن يختار أكثر من Agent من نفس العائلة
    if task_type == "debug":
        cmd = f"./hf_run_debug_expert.sh '{desc}'"
    elif task_type == "architecture":
        cmd = f"./hf_run_system_architect.sh '{desc}'"
    elif task_type == "coaching":
        cmd = f"./hf_run_technical_coach.sh '{desc}'"
    elif task_type == "knowledge":
        cmd = f"./hf_run_knowledge_spider.sh '{desc}'"
    elif task_type == "pipeline":
        cmd = f"./hf_run_pipeline_manager.sh '{desc}'"
    else:
        cmd = f"./hf_smart_decision_engine.sh '{desc}'"

    print("💡 أمر التنفيذ المقترح (يدويًا):")
    print(f"   {cmd}")


def list_queue():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, created_at, task_type, priority, status, substr(description,1,80)
        FROM tasks
        WHERE status = 'queued'
        ORDER BY created_at ASC
        """
    )
    rows = cur.fetchall()
    conn.close()

    if not rows:
        print("ℹ️ لا توجد مهام في حالة queued.")
        return

    print("📋 قائمة المهام (status=queued):")
    for r in rows:
        tid, created_at, ttype, prio, status, short_desc = r
        print(f"- #{tid} [{prio}/{ttype}] @ {created_at}: {short_desc}")


def main():
    parser = argparse.ArgumentParser(description="Hyper Factory Orchestrator (multi-agent families)")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("init-agents", help="تحميل العمال من all_agents_complete.json إلى قاعدة البيانات")

    p_new = sub.add_parser("new-task", help="إنشاء مهمة جديدة")
    p_new.add_argument("description")
    p_new.add_argument("priority", nargs="?", default="normal")

    sub.add_parser("assign-next", help="إسناد أول مهمة في الطابور queued إلى عامل مناسب")
    sub.add_parser("list-queue", help="عرض المهام في حالة queued")

    args = parser.parse_args()

    if args.command == "init-agents":
        init_agents_from_json()
    elif args.command == "new-task":
        new_task(args.description, args.priority)
    elif args.command == "assign-next":
        assign_next()
    elif args.command == "list-queue":
        list_queue()
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
