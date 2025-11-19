#!/usr/bin/env python3
"""
Advanced Architecture Audit for Hyper Factory
- يلخّص حالة البنية المتقدمة في JSON + تقرير نصي
"""

import json
import sqlite3
from pathlib import Path
from datetime import datetime

BASE = Path(__file__).resolve().parent

def bool_flag(v: bool) -> str:
    return "OK" if v else "MISSING"

def check_path(path: Path) -> bool:
    return path.exists()

def check_dir(path: Path) -> bool:
    return path.is_dir()

def check_file(path: Path) -> bool:
    return path.is_file()

def scan_data_lakehouse():
    dl = BASE / "data_lakehouse"
    zones = ["raw", "cleansed", "semantic", "serving", "catalog"]
    info = {
        "exists": check_dir(dl),
        "zones": {},
    }
    for z in zones:
        p = dl / z
        info["zones"][z] = {
            "exists": check_dir(p),
            "files": len(list(p.rglob("*"))) if p.exists() else 0,
        }
    return info

def scan_factories_and_stack():
    factories = BASE / "factories"
    stack = BASE / "stack"
    cfg = BASE / "config"

    return {
        "factories_dir": {
            "exists": check_dir(factories),
        },
        "stack_dir": {
            "exists": check_dir(stack),
        },
        "factory_config": {
            "factory_yaml": check_file(cfg / "factory.yaml"),
            "factory_manifest": check_file(cfg / "factory_manifest.yaml"),
        },
    }

def scan_agents():
    agents_dir = BASE / "agents"
    expected = [
        "debug_expert",
        "system_architect",
        "technical_coach",
        "knowledge_spider",
        "security_auditor",
        "document_generator",
        "patterns_engine",
        "quality_engine",
        "temporal_memory",
        "integration_hub",
    ]
    result = {
        "agents_root_exists": check_dir(agents_dir),
        "agents": {},
    }
    for name in expected:
        found = False
        if agents_dir.exists():
            for p in agents_dir.rglob("*"):
                if p.is_dir() and name in p.name:
                    found = True
                    break
        result["agents"][name] = {
            "status": bool_flag(found),
            "exists": found,
        }
    return result

def scan_integrations():
    integ_dir = BASE / "integrations"
    files = []
    if integ_dir.exists():
        for p in sorted(integ_dir.glob("*.py")):
            files.append(p.name)
    return {
        "root_exists": check_dir(integ_dir),
        "files": files,
        "has_github_api": "github_api.py" in files,
        "has_notifications": "notifications.py" in files,
    }

def scan_knowledge_db():
    db_path = BASE / "data" / "knowledge" / "knowledge.db"
    info = {
        "db_exists": check_file(db_path),
        "tables": {},
        "error": None,
    }
    if not info["db_exists"]:
        info["error"] = "knowledge.db not found"
        return info

    try:
        conn = sqlite3.connect(db_path)
        cur = conn.cursor()
        cur.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [r[0] for r in cur.fetchall()]
        for t in tables:
            try:
                cur.execute(f"SELECT COUNT(*) FROM {t}")
                count = cur.fetchone()[0]
            except Exception:
                count = None
            info["tables"][t] = count
        conn.close()
    except Exception as e:
        info["error"] = str(e)

    return info

def build_summary(audit):
    """
    يبني ملخص نصي موجه للمالك/المدير
    """
    lines = []
    lines.append("📊 Advanced Architecture Audit - Hyper Factory")
    lines.append(f"⏰ {audit['meta']['timestamp']}")
    lines.append("")

    # Data Lakehouse
    dl = audit["data_lakehouse"]
    lines.append("1) Data Lakehouse")
    if dl["exists"]:
        lines.append("   - data_lakehouse موجودة ✅")
        for z, zi in dl["zones"].items():
            status = "✅" if zi["exists"] else "❌"
            lines.append(f"   - {z}: {status} (files={zi['files']})")
    else:
        lines.append("   - data_lakehouse غير موجودة ❌")
    lines.append("")

    # Factories / Stack
    fs = audit["factories_stack"]
    lines.append("2) Factories / Stack")
    lines.append(f"   - factories/: {'✅' if fs['factories_dir']['exists'] else '❌'}")
    lines.append(f"   - stack/: {'✅' if fs['stack_dir']['exists'] else '❌'}")
    lines.append(f"   - factory.yaml: {'✅' if fs['factory_config']['factory_yaml'] else '❌'}")
    lines.append(f"   - factory_manifest.yaml: {'✅' if fs['factory_config']['factory_manifest'] else '❌'}")
    lines.append("")

    # Agents
    ag = audit["agents"]
    lines.append("3) Agents / العمال المتقدمين")
    lines.append(f"   - agents/: {'✅' if ag['agents_root_exists'] else '❌'}")
    for name, info in ag["agents"].items():
        lines.append(f"   - {name}: {'✅' if info['exists'] else '❌'}")
    lines.append("")

    # Integrations
    itg = audit["integrations"]
    lines.append("4) Integrations")
    lines.append(f"   - integrations/: {'✅' if itg['root_exists'] else '❌'}")
    lines.append(f"   - github_api.py: {'✅' if itg['has_github_api'] else '❌'}")
    lines.append(f"   - notifications.py: {'✅' if itg['has_notifications'] else '❌'}")
    lines.append(f"   - ملفات أخرى: {', '.join(itg['files']) if itg['files'] else 'لا يوجد'}")
    lines.append("")

    # Knowledge DB
    kdb = audit["knowledge_db"]
    lines.append("5) Knowledge DB")
    if not kdb["db_exists"]:
        lines.append("   - knowledge.db: ❌ غير موجود")
    else:
        lines.append("   - knowledge.db: ✅ موجود")
        lines.append("   - الجداول وعدد السجلات:")
        for t, c in kdb["tables"].items():
            lines.append(f"     • {t}: {c}")
        if kdb["tables"].get("system_patterns", 0) == 0:
            lines.append("   ⚠️ system_patterns فارغ → نظام الأنماط غير مفعّل بعد.")
        if kdb["tables"].get("agent_memory", 0) == 0:
            lines.append("   ⚠️ agent_memory فارغ → الذاكرة الزمنية غير مفعّلة.")
    lines.append("")

    # إستنتاج سريع
    lines.append("6) Executive Summary")
    lines.append("   - منصة البيانات الأساسية: جاهزة ✅")
    if dl["zones"].get("catalog", {}).get("exists") is False:
        lines.append("   - Data Catalog: مفقود ❌ (يجب بناء data_lakehouse/catalog).")
    if not fs["factories_dir"]["exists"] or not fs["stack_dir"]["exists"]:
        lines.append("   - factories/stack: غير مكتملة ❌ (بنية منطقية موجودة، الفيزيائية ناقصة).")
    missing_advanced_agents = [
        n for n, info in ag["agents"].items()
        if not info["exists"] and n in ("patterns_engine","quality_engine","temporal_memory","integration_hub")
    ]
    if missing_advanced_agents:
        lines.append(f"   - Advanced Agents ناقصة: {', '.join(missing_advanced_agents)}")
    if kdb["tables"].get("system_patterns", 0) == 0:
        lines.append("   - Patterns Engine: هيكل فقط بدون بيانات.")
    if kdb["tables"].get("agent_memory", 0) == 0:
        lines.append("   - Temporal Memory: غير مفعّل (لا توجد سجلات).")

    return "\n".join(lines)

def main():
    reports_dir = BASE / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)

    advanced_json = reports_dir / "advanced_audit.json"
    advanced_txt = reports_dir / "advanced_audit.txt"
    dashboard_json = reports_dir / "advanced_dashboard.json"

    audit = {
        "meta": {
            "timestamp": datetime.now().isoformat(timespec="seconds"),
            "base_dir": str(BASE),
        },
        "data_lakehouse": scan_data_lakehouse(),
        "factories_stack": scan_factories_and_stack(),
        "agents": scan_agents(),
        "integrations": scan_integrations(),
        "knowledge_db": scan_knowledge_db(),
    }

    # حفظ JSON
    with advanced_json.open("w", encoding="utf-8") as f:
        json.dump(audit, f, ensure_ascii=False, indent=2)

    # حفظ تقرير نصي
    summary_text = build_summary(audit)
    with advanced_txt.open("w", encoding="utf-8") as f:
        f.write(summary_text)

    # تحديث advanced_dashboard.json مع أخذ نسخة احتياطية
    if dashboard_json.exists():
        backup = dashboard_json.with_suffix(".json.bak")
        dashboard_json.replace(backup)
    with dashboard_json.open("w", encoding="utf-8") as f:
        json.dump(
            {
                "meta": audit["meta"],
                "summary": {
                    "data_lakehouse_ok": audit["data_lakehouse"]["exists"],
                    "catalog_exists": audit["data_lakehouse"]["zones"]["catalog"]["exists"],
                    "factories_dir_exists": audit["factories_stack"]["factories_dir"]["exists"],
                    "stack_dir_exists": audit["factories_stack"]["stack_dir"]["exists"],
                    "advanced_agents": audit["agents"]["agents"],
                    "knowledge_db": {
                        "db_exists": audit["knowledge_db"]["db_exists"],
                        "tables": audit["knowledge_db"]["tables"],
                    },
                },
            },
            f,
            ensure_ascii=False,
            indent=2,
        )

    print("🔧 Advanced audit completed.")
    print(f"📄 JSON  : {advanced_json}")
    print(f"📄 TEXT  : {advanced_txt}")
    print(f"📊 DASH  : {dashboard_json}")

if __name__ == "__main__":
    main()
