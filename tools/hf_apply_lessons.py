#!/usr/bin/env python3
import sqlite3
import json
import sys
import shutil
import datetime
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: مكتبة PyYAML غير مثبتة. نفّذ:", file=sys.stderr)
    print("  pip install pyyaml", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "data" / "knowledge" / "knowledge.db"
CONFIG_DIR = ROOT / "config"
REPORTS_CONFIG_DIR = ROOT / "reports" / "config_changes"
BACKUP_DIR = CONFIG_DIR / "backup"

BACKUP_DIR.mkdir(parents=True, exist_ok=True)
REPORTS_CONFIG_DIR.mkdir(parents=True, exist_ok=True)

TS = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")


def load_yaml(path: Path):
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data or {}


def save_yaml(data, path: Path):
    with path.open("w", encoding="utf-8") as f:
        yaml.safe_dump(
            data,
            f,
            sort_keys=False,
            allow_unicode=True,
            default_flow_style=False,
        )


def apply_path(config: dict, dot_path: str, value, operation: str):
    """
    تطبيق تعديل على config وفق dot_path:
    operation: set | increment
    """
    keys = dot_path.split(".")
    cur = config
    for k in keys[:-1]:
        if k not in cur or not isinstance(cur[k], dict):
            cur[k] = {}
        cur = cur[k]
    last = keys[-1]
    old_value = cur.get(last, None)

    if operation == "set":
        cur[last] = value
    elif operation == "increment":
        try:
            base = old_value if isinstance(old_value, (int, float)) else 0
            add = value if isinstance(value, (int, float)) else 0
            cur[last] = base + add
        except Exception:
            # fallback: set
            cur[last] = value
    else:
        raise ValueError(f"Unsupported operation: {operation}")

    return old_value, cur[last]


def main():
    print("=== Hyper Factory – Apply Lessons ===")
    print(f"ROOT: {ROOT}")
    if not DB_PATH.exists():
        print(f"ERROR: knowledge DB غير موجود: {DB_PATH}")
        sys.exit(1)

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    cur.execute(
        """
        SELECT id, item_key, title, body, importance, tags, meta_json
        FROM knowledge_items
        WHERE item_type = 'lesson'
        ORDER BY id
        """
    )
    rows = cur.fetchall()
    conn.close()

    if not rows:
        print("INFO: لا توجد عناصر lesson في knowledge_items – لا شيء لتطبيقه.")
        return

    print(f"INFO: عدد الدروس المستخرجة من DB: {len(rows)}")

    agents_cfg_path = CONFIG_DIR / "agents.yaml"
    factory_cfg_path = CONFIG_DIR / "factory.yaml"

    agents_cfg = load_yaml(agents_cfg_path)
    factory_cfg = load_yaml(factory_cfg_path)

    # نسخ احتياطية (مرة واحدة لكل ملف عند أول تعديل)
    agents_backup_path = None
    factory_backup_path = None

    changes = []
    skipped = []

    for row in rows:
        lesson_id = row["id"]
        item_key = row["item_key"]
        title = row["title"] or ""
        importance = row["importance"] if row["importance"] is not None else 0.0
        tags = (row["tags"] or "").strip()
        meta_json = row["meta_json"] or ""

        # محاولة قراءة meta_json
        try:
            meta = json.loads(meta_json) if meta_json else {}
        except Exception as exc:
            skipped.append(
                {
                    "lesson_id": lesson_id,
                    "item_key": item_key,
                    "reason": f"meta_json غير صالح: {exc}",
                }
            )
            continue

        enabled = meta.get("enabled", True)
        if not enabled:
            skipped.append(
                {
                    "lesson_id": lesson_id,
                    "item_key": item_key,
                    "reason": "الدرس معطّل enabled=false",
                }
            )
            continue

        target = meta.get("target") or meta.get("config_target")
        dot_path = meta.get("path") or meta.get("config_path")
        value = meta.get("value")
        operation = meta.get("operation", "set")

        if not target or not dot_path:
            skipped.append(
                {
                    "lesson_id": lesson_id,
                    "item_key": item_key,
                    "reason": "meta_json بدون target/path",
                }
            )
            continue

        target = str(target).lower().strip()
        if target in ["agents", "agent", "agents.yaml"]:
            cfg_name = "agents"
            cfg_path = agents_cfg_path
            cfg_obj = agents_cfg
        elif target in ["factory", "factory.yaml"]:
            cfg_name = "factory"
            cfg_path = factory_cfg_path
            cfg_obj = factory_cfg
        else:
            skipped.append(
                {
                    "lesson_id": lesson_id,
                    "item_key": item_key,
                    "reason": f"target غير مدعوم: {target}",
                }
            )
            continue

        # حفظ نسخة احتياطية مرة واحدة لكل ملف
        if cfg_name == "agents" and agents_backup_path is None and cfg_path.exists():
            agents_backup_path = BACKUP_DIR / f"agents.yaml.{TS}"
            shutil.copy2(cfg_path, agents_backup_path)
        if cfg_name == "factory" and factory_backup_path is None and cfg_path.exists():
            factory_backup_path = BACKUP_DIR / f"factory.yaml.{TS}"
            shutil.copy2(cfg_path, factory_backup_path)

        try:
            old_value, new_value = apply_path(cfg_obj, dot_path, value, operation)
        except Exception as exc:
            skipped.append(
                {
                    "lesson_id": lesson_id,
                    "item_key": item_key,
                    "reason": f"فشل تطبيق المسار {dot_path}: {exc}",
                }
            )
            continue

        changes.append(
            {
                "lesson_id": lesson_id,
                "item_key": item_key,
                "title": title,
                "importance": importance,
                "target": cfg_name,
                "path": dot_path,
                "operation": operation,
                "old_value": old_value,
                "new_value": new_value,
                "config_file": str(cfg_path.relative_to(ROOT)),
                "tags": tags,
            }
        )

    # حفظ التعديلات على ملفات YAML
    if changes:
        if agents_backup_path:
            print(f"INFO: تم حفظ نسخة احتياطية لـ agents.yaml: {agents_backup_path}")
        if factory_backup_path:
            print(f"INFO: تم حفظ نسخة احتياطية لـ factory.yaml: {factory_backup_path}")

        save_yaml(agents_cfg, agents_cfg_path)
        save_yaml(factory_cfg, factory_cfg_path)

    # إنشاء تقرير config_changes
    report = {
        "created_at_utc": TS,
        "root": str(ROOT),
        "db_path": str(DB_PATH),
        "lessons_total": len(rows),
        "changes_applied": len(changes),
        "skipped": skipped,
        "changes": changes,
    }
    report_path = REPORTS_CONFIG_DIR / f"apply_lessons_{TS}.json"
    with report_path.open("w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    print(f"=== ملخص تطبيق الدروس ===")
    print(f"- عدد الدروس في DB        : {len(rows)}")
    print(f"- عدد التغييرات المطبقة   : {len(changes)}")
    print(f"- عدد الدروس المتخطاة     : {len(skipped)}")
    print(f"- تقرير التغييرات         : {report_path}")

    if changes:
        print("\nأهم التغييرات:")
        for ch in changes:
            print(
                f"* [lesson_id={ch['lesson_id']}] target={ch['target']} "
                f"path={ch['path']} old={ch['old_value']!r} -> new={ch['new_value']!r}"
            )

    if skipped:
        print("\nملاحظات حول الدروس المتخطاة:")
        for sk in skipped:
            print(
                f"- [lesson_id={sk['lesson_id']}] item_key={sk['item_key']}: {sk['reason']}"
            )


if __name__ == "__main__":
    main()
