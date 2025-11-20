#!/usr/bin/env python3
# Hyper Factory – Manager Brain (dynamic workers dispatcher)

import os
import sqlite3
from pathlib import Path
from datetime import datetime

ROOT = Path("/root/hyper-factory")
DB_FACTORY = ROOT / "data/factory/factory.db"
RUN_DIR = ROOT / "run"
RUN_DIR.mkdir(parents=True, exist_ok=True)

plan_txt = RUN_DIR / "manager_execution_plan.txt"

def log(msg: str):
    print(msg)

def detect_tasks_table(conn):
    cur = conn.cursor()
    cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [r[0] for r in cur.fetchall()]
    for t in tables:
        cur.execute(f"PRAGMA table_info({t})")
        cols = {r[1] for r in cur.fetchall()}
        if {"status", "agent_id"} <= cols:
            return t
    return None

def load_agents(conn):
    cur = conn.cursor()
    try:
        cur.execute("SELECT id, family, role, level, status, success_rate, total_runs "
                    "FROM agents")
    except sqlite3.Error as e:
        log(f"⚠️ لا يمكن قراءة جدول agents: {e}")
        return {}
    agents = {}
    for row in cur.fetchall():
        aid, family, role, level, status, succ, runs = row
        agents[aid] = {
            "id": aid,
            "family": family,
            "role": role,
            "level": level,
            "status": status,
            "success_rate": succ or 0.0,
            "total_runs": runs or 0,
        }
    return agents

def build_queue_stats(conn, tasks_table):
    cur = conn.cursor()
    try:
        cur.execute(f"SELECT agent_id, status, COUNT(*) "
                    f"FROM {tasks_table} GROUP BY agent_id, status")
    except sqlite3.Error as e:
        log(f"⚠️ لا يمكن قراءة {tasks_table}: {e}")
        return {}, 0, 0

    stats = {}
    total_queued = 0
    total_assigned = 0
    for agent_id, status, cnt in cur.fetchall():
        stats.setdefault(agent_id, {"queued": 0, "assigned": 0})
        if status == "queued":
            stats[agent_id]["queued"] += cnt
            total_queued += cnt
        elif status == "assigned":
            stats[agent_id]["assigned"] += cnt
            total_assigned += cnt
    return stats, total_queued, total_assigned

def find_run_script(agent_id: str) -> str | None:
    """
    نحاول نلاقي سكربت تشغيل للـ agent:
    - الشكل الأساسي: hf_run_<agent_id>.sh
    - يتم البحث في ROOT مباشرة فقط (بسيط وواضح).
    """
    candidate = ROOT / f"hf_run_{agent_id}.sh"
    if candidate.exists() and os.access(candidate, os.X_OK):
        return str(candidate)

    # لو الاسم فيه حروف غريبة، ما نختَرعش مسارات جديدة – نرجع None
    return None

def compute_priority(agent, qstats):
    base = 0.0

    # وزن حسب الـ family
    family = (agent.get("family") or "").lower()
    if family == "pipeline":
        base += 3.0
    elif family in ("knowledge", "architecture"):
        base += 2.5
    elif family in ("debugging", "quality"):
        base += 2.0
    elif family in ("training",):
        base += 1.5

    # وزن حسب النجاح
    succ = agent.get("success_rate") or 0.0
    base += succ / 20.0  # 100% نجاح = +5 نقاط

    # وزن حسب حجم الـ queue
    queued = qstats.get("queued", 0)
    base += min(queued / 100.0, 5.0)  # كل 100 مهمة = +1 حتى حد +5

    return base

def build_plan():
    if not DB_FACTORY.exists():
        log(f"⚠️ factory.db غير موجود: {DB_FACTORY}")
        plan_txt.write_text("# لا يوجد factory.db – لا خطة.\n", encoding="utf-8")
        return

    conn = sqlite3.connect(DB_FACTORY)
    try:
        tasks_table = detect_tasks_table(conn)
        if not tasks_table:
            log("⚠️ لم يتم العثور على جدول مهام يحتوي على (status, agent_id).")
            plan_txt.write_text("# لا يوجد جدول مهام متوافق – لا خطة.\n", encoding="utf-8")
            return

        agents = load_agents(conn)
        qstats, total_queued, total_assigned = build_queue_stats(conn, tasks_table)

        lines = []
        header = [
            f"# Hyper Factory – Manager Execution Plan",
            f"# وقت الخطة: {datetime.now().isoformat(timespec='seconds')}",
            f"# جدول المهام: {tasks_table}",
            f"# إجمالي queued: {total_queued}",
            f"# إجمالي assigned: {total_assigned}",
            "",
        ]
        lines.extend(header)

        if total_queued == 0:
            lines.append("# لا توجد مهام في حالة queued – لا أوامر للتنفيذ.")
            plan_txt.write_text("\n".join(lines) + "\n", encoding="utf-8")
            log("✅ لا يوجد queue – لا حاجة لتشغيل عمال إضافيين.")
            return

        # حساب أولوية لكل agent
        items = []
        for aid, agent in agents.items():
            stats = qstats.get(aid, {"queued": 0, "assigned": 0})
            queued = stats["queued"]
            if queued <= 0:
                continue
            if (agent.get("status") or "") != "active":
                continue

            run_script = find_run_script(aid)
            if not run_script:
                # ما فيش سكربت تشغيل واضح لهذا الـ agent – نتخطى بس نسجل ملاحظة
                lines.append(f"# ⚠️ لا يوجد سكربت تشغيل معروف للـ agent {aid} – تم التخطي.")
                continue

            priority = compute_priority(agent, stats)
            items.append({
                "agent_id": aid,
                "queued": queued,
                "assigned": stats["assigned"],
                "priority": priority,
                "run_script": run_script,
            })

        if not items:
            lines.append("# لا توجد عناصر لها سكربت تشغيل صالح – لا خطة تنفيذ.")
            plan_txt.write_text("\n".join(lines) + "\n", encoding="utf-8")
            log("⚠️ لا توجد أوامر صالحة للتنفيذ (سكربتات مفقودة؟).")
            return

        # ترتيب حسب الأولوية ثم حجم الـ queue
        items.sort(key=lambda x: (-x["priority"], -x["queued"]))

        lines.append("# أوامر التنفيذ (مرتبة حسب الأولوية):")
        for item in items:
            aid = item["agent_id"]
            q = item["queued"]
            a = item["assigned"]
            p = item["priority"]
            cmd = item["run_script"]

            # نقرر كم مرة نشغل السكربت في هذه الدورة
            # قاعدة بسيطة: مرة واحدة + واحدة إضافية لكل 1000 في الـ queue (حد أقصى 5).
            extra = min(max(q // 1000, 0), 4)
            runs = 1 + extra

            lines.append(f"# agent={aid} queued={q} assigned={a} priority={p:.2f} runs={runs}")
            for i in range(runs):
                lines.append(f"CMD {cmd}  # agent={aid} run={i+1}/{runs}")

        plan_txt.write_text("\n".join(lines) + "\n", encoding="utf-8")
        log(f"✅ تم بناء خطة المدير: {plan_txt}")

    finally:
        conn.close()

if __name__ == "__main__":
    build_plan()
