#!/usr/bin/env python3
"""
tools/hf_smart_worker.py

العامل الذكي (Smart Worker):
- يقرأ insights.json + quality_status.json
- يبني قائمة توصيات تشغيلية (Recommended Actions)
- يكتب:
  - ai/memory/smart_actions.json
  - ai/memory/smart_actions.txt
"""

import os
import json
from datetime import datetime
from typing import Dict, Any, List

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEMORY_DIR = os.path.join(ROOT, "ai", "memory")

INSIGHTS_JSON = os.path.join(MEMORY_DIR, "insights.json")
QUALITY_STATUS_JSON = os.path.join(MEMORY_DIR, "quality_status.json")

ACTIONS_JSON = os.path.join(MEMORY_DIR, "smart_actions.json")
ACTIONS_TXT = os.path.join(MEMORY_DIR, "smart_actions.txt")


def safe_load(path: str) -> Dict[str, Any]:
    if not os.path.exists(path):
        return {}
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def build_actions(insights: Dict[str, Any], quality: Dict[str, Any]) -> List[Dict[str, Any]]:
    actions: List[Dict[str, Any]] = []

    status = (quality.get("status") or {})
    overall = status.get("overall_status", "UNKNOWN")
    success_rate = float(status.get("success_rate", 0.0) or 0.0)
    total_runs = int(status.get("total_runs", 0) or 0)

    # 1) توصية عامة حسب اللون
    if overall == "GREEN":
        actions.append(
            {
                "id": "pipeline_green_scale_usage",
                "title": "استقرار مرتفع - يمكن زيادة الاستخدام",
                "priority": "MEDIUM",
                "tags": ["pipeline", "stability", "scale"],
                "description": (
                    "حالة الجودة GREEN ونسبة النجاح مرتفعة. "
                    "يمكن زيادة عدد الدورات أو إدخال مصادر بيانات جديدة تدريجياً مع مراقبة الجودة."
                ),
            }
        )
    elif overall == "YELLOW":
        actions.append(
            {
                "id": "pipeline_yellow_focus_monitoring",
                "title": "حالة متوسطة - ركّز على المراقبة وتحسين النقاط الضعيفة",
                "priority": "HIGH",
                "tags": ["pipeline", "monitoring", "risk"],
                "description": (
                    "حالة الجودة YELLOW. يُنصح بتقليل أي تغييرات كبيرة حالياً، "
                    "وتحليل العمال ذات الفشل الأعلى، وتحسينها قبل التوسع."
                ),
            }
        )
    elif overall == "RED":
        actions.append(
            {
                "id": "pipeline_red_stop_and_fix",
                "title": "حالة حرجة - أوقف التوسع وابدأ الإصلاح",
                "priority": "CRITICAL",
                "tags": ["pipeline", "incident", "risk"],
                "description": (
                    "حالة الجودة RED. يُنصح بإيقاف أي توسع أو تشغيل إضافي "
                    "والتركيز على إصلاح الأخطاء في العمال المتضررة قبل الاستمرار."
                ),
            }
        )
    else:
        actions.append(
            {
                "id": "pipeline_unknown_bootstrap",
                "title": "لا توجد بيانات كافية - شغّل المزيد من الدورات",
                "priority": "MEDIUM",
                "tags": ["bootstrap", "data"],
                "description": (
                    "حالة الجودة غير معروفة أو عدد الدورات قليل جداً. "
                    "يُفضل تشغيل المزيد من الدورات لتجميع بيانات كافية قبل اتخاذ قرارات تشغيلية."
                ),
            }
        )

    # 2) تحليل العمال ذات الفشل الأعلى
    top_problems = (status.get("top_problems") or [])[:3]
    for p in top_problems:
        name = p.get("name")
        fail = p.get("fail", 0)
        fail_rate = float(p.get("fail_rate", 0.0) or 0.0)
        if not name or fail <= 0:
            continue

        actions.append(
            {
                "id": f"investigate_{name}",
                "title": f"تحليل العامل: {name}",
                "priority": "HIGH" if fail_rate >= 0.2 else "MEDIUM",
                "tags": ["worker", "debug", name],
                "description": (
                    f"العامل {name} لديه فشل مسجّل (fail={fail}, fail_rate={fail_rate:.2%}). "
                    "يُوصى بمراجعة لوجات هذا العامل، وإضافة فحوصات/اختبارات له، "
                    "وتحسين التعامل مع الحالات الحدودية."
                ),
            }
        )

    # 3) توصيات بناءً على حجم البيانات
    if total_runs >= 50 and success_rate >= 0.9:
        actions.append(
            {
                "id": "start_experiments",
                "title": "كفاية بيانات لتجارب متقدمة",
                "priority": "MEDIUM",
                "tags": ["experiments", "models"],
                "description": (
                    "هناك عدد كافٍ من الدورات الناجحة، يمكن البدء في بناء عمال أذكى "
                    "(مثل Trainer أو Analyzer متقدم) اعتماداً على البيانات التاريخية."
                ),
            }
        )
    elif total_runs < 10:
        actions.append(
            {
                "id": "increase_run_volume",
                "title": "رفع عدد الدورات لجمع بيانات",
                "priority": "MEDIUM",
                "tags": ["data_volume"],
                "description": (
                    "عدد الدورات المسجلة قليل. يُفضّل جدولة تشغيل دوري لـ run_basic_with_memory.sh "
                    "لزيادة البيانات قبل أي خطوة تعلم أو تحسين متقدم."
                ),
            }
        )

    # 4) توصية خاصة بزمن آخر تشغيل
    last_run_at = insights.get("last_run_at")
    if last_run_at:
        actions.append(
            {
                "id": "monitor_freshness",
                "title": "مراجعة حداثة بيانات التشغيل",
                "priority": "LOW",
                "tags": ["freshness"],
                "description": (
                    f"آخر تشغيل مسجّل في insights عند: {last_run_at}. "
                    "تأكد أن هذا التوقيت متوافق مع نمط التشغيل المتوقع (مثلاً تشغيل كل X دقائق/ساعات)."
                ),
            }
        )

    return actions


def write_actions(actions: List[Dict[str, Any]]) -> None:
    os.makedirs(MEMORY_DIR, exist_ok=True)
    now_iso = datetime.utcnow().isoformat() + "Z"

    payload = {
        "generated_at": now_iso,
        "actions": actions,
    }

    with open(ACTIONS_JSON, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

    lines: List[str] = []
    lines.append("===== Hyper Factory Smart Actions =====")
    lines.append(f"Generated at : {now_iso}")
    lines.append(f"Total actions: {len(actions)}")
    lines.append("")

    for i, a in enumerate(actions, start=1):
        lines.append(f"[{i}] {a['title']}")
        lines.append(f"    id       : {a['id']}")
        lines.append(f"    priority : {a['priority']}")
        lines.append(f"    tags     : {', '.join(a.get('tags', []))}")
        lines.append(f"    desc     : {a['description']}")
        lines.append("")

    with open(ACTIONS_TXT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    print("✅ تم توليد توصيات العامل الذكي:")
    print(f"   - {ACTIONS_JSON}")
    print(f"   - {ACTIONS_TXT}")


def main():
    print("📂 MEMORY_DIR :", MEMORY_DIR)
    print("📄 INSIGHTS   :", INSIGHTS_JSON)
    print("📄 QUALITY    :", QUALITY_STATUS_JSON)
    print("----------------------------------------")

    insights_root = safe_load(INSIGHTS_JSON)
    insights = insights_root if isinstance(insights_root, dict) else {}
    quality_root = safe_load(QUALITY_STATUS_JSON)
    quality = quality_root if isinstance(quality_root, dict) else {}

    if not insights:
        print("⚠️ لا توجد insights.json بعد. شغّل run_basic_with_memory.sh أولاً.")
    if not quality:
        print("⚠️ لا توجد quality_status.json بعد. شغّل hf_run_quality_worker.sh أولاً.")

    if not insights or not quality:
        print("ℹ️ لن يتم توليد توصيات بدون كلا الملفين.")
        return

    actions = build_actions(insights, quality)
    write_actions(actions)


if __name__ == "__main__":
    main()
