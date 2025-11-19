#!/usr/bin/env python3
"""
tools/hf_system_architect.py

System Architect Worker:
- يقرأ design/intents/*.md (أفكار/نوايا التصميم)
- يبني لكل intent ملف تصميم معماري منظم تحت reports/architecture/
- يدمج حالة الـ Golden Pipeline (إن توفرت) من ai/memory/quality_status.json
"""

import os
import json
from datetime import datetime
from typing import Optional, Dict, Any, List

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DESIGN_DIR = os.path.join(ROOT, "design")
INTENTS_DIR = os.path.join(DESIGN_DIR, "intents")

REPORTS_DIR = os.path.join(ROOT, "reports")
ARCH_DIR = os.path.join(REPORTS_DIR, "architecture")

MEMORY_DIR = os.path.join(ROOT, "ai", "memory")
QUALITY_STATUS_JSON = os.path.join(MEMORY_DIR, "quality_status.json")


def ensure_dirs() -> None:
    os.makedirs(DESIGN_DIR, exist_ok=True)
    os.makedirs(INTENTS_DIR, exist_ok=True)
    os.makedirs(REPORTS_DIR, exist_ok=True)
    os.makedirs(ARCH_DIR, exist_ok=True)


def load_quality_status() -> Optional[Dict[str, Any]]:
    if not os.path.exists(QUALITY_STATUS_JSON):
        return None
    try:
        with open(QUALITY_STATUS_JSON, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def read_intent(path: str) -> Dict[str, Any]:
    """
    يقرأ ملف intent (Markdown) ويستخرج:
    - title: من أول سطر يبدأ بـ #
    - raw_text: النص الكامل
    """
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()

    title: str = os.path.splitext(os.path.basename(path))[0]
    lines = text.splitlines()

    for line in lines:
        stripped = line.strip()
        if stripped.startswith("#"):
            # نزيل # والعلامات الإضافية
            title_candidate = stripped.lstrip("#").strip()
            if title_candidate:
                title = title_candidate
                break

    return {
        "title": title,
        "raw_text": text,
        "lines": lines,
    }


def format_quality_section(quality: Optional[Dict[str, Any]]) -> str:
    if quality is None:
        return (
            "### Pipeline Health\n"
            "- Status      : UNKNOWN\n"
            "- Note        : لا يوجد ملف quality_status.json بعد.\n"
            "- Action      : شغّل `hf_run_quality_worker.sh` لبناء حالة الجودة.\n"
        )

    status = quality.get("status", "UNKNOWN")
    risk_level = quality.get("risk_level", "UNKNOWN")
    success_rate = quality.get("success_rate", None)
    total_runs = quality.get("total_runs", None)
    failed_runs = quality.get("failed_runs", None)
    updated_at = quality.get("updated_at", "")

    lines: List[str] = []
    lines.append("### Pipeline Health")
    lines.append(f"- Status      : {status}")
    lines.append(f"- Risk level  : {risk_level}")
    if success_rate is not None:
        lines.append(f"- Success rate: {success_rate:.2%}")
    if total_runs is not None:
        lines.append(f"- Total runs  : {total_runs}")
    if failed_runs is not None:
        lines.append(f"- Failed runs : {failed_runs}")
    if updated_at:
        lines.append(f"- Updated at  : {updated_at}")
    return "\n".join(lines) + "\n"


def build_design_markdown(intent_path: str, intent_info: Dict[str, Any], quality: Optional[Dict[str, Any]]) -> str:
    now_iso = datetime.utcnow().isoformat() + "Z"
    intent_name = os.path.basename(intent_path)
    title = intent_info["title"]
    raw_text = intent_info["raw_text"]

    quality_section = format_quality_section(quality)

    md: List[str] = []
    md.append(f"# System Design: {title}")
    md.append("")
    md.append("## Metadata")
    md.append(f"- Generated at   : {now_iso}")
    md.append(f"- Source intent  : {intent_name}")
    md.append(f"- Tool           : hf_system_architect.py")
    md.append("")

    md.append("## 1. Context & Intent")
    md.append("")
    md.append("> **Original Intent (from design/intents):**")
    md.append("")
    # نضع النص الأصلي كـ quote block للحفاظ عليه
    for line in raw_text.splitlines():
        if line.strip():
            md.append(f"> {line}")
        else:
            md.append(">")
    md.append("")

    md.append("## 2. Current Golden Pipeline (Reference)")
    md.append("")
    md.append(
        "- **Name**      : Hyper Factory Golden Pipeline v0.1\n"
        "- **Stages**    : ingestor_basic → processor_basic → analyzer_basic → reporter_basic\n"
        "- **Memory**    : Online Memory + Offline Learner\n"
        "- **Reporting** : basic_runs.log, summary_basic.*, semantic_*, smart_actions.*\n"
    )
    md.append("")
    md.append("### 2.1 Core Data Flow")
    md.append("")
    md.append(
        "```text\n"
        "data/inbox/  →  data/raw/  →  data/processed/  →  data/semantic/  →  data/serving/\n"
        "                          ↘ reports/basic_runs.log, data/report/summary_basic.*\n"
        "                          ↘ ai/memory/messages.jsonl, insights.*, quality.*, smart_actions.*\n"
        "```"
    )
    md.append("")

    md.append("### 2.2 Pipeline Health Snapshot")
    md.append("")
    md.append(quality_section)
    md.append("")

    md.append("## 3. Proposed System Components")
    md.append("")
    md.append(
        "- **High-level Objective**: ترجمة نية الـ intent إلى مكوّنات واضحة (workers, configs, reports).\n"
        "- **Candidate Components** (مبدئية):\n"
        "  - New worker(s) inside `tools/` أو `agents/`.\n"
        "  - تكامل مع الذاكرة (ai/memory/) إن لزم.\n"
        "  - تقارير إضافية تحت `reports/` أو `data/report/`.\n"
    )
    md.append("")
    md.append("### 3.1 Data Inputs")
    md.append("")
    md.append(
        "- Existing inputs:\n"
        "  - data/raw/, data/processed/, data/semantic/\n"
        "  - reports/basic_runs.log, data/report/summary_basic.*\n"
        "  - ai/memory/messages.jsonl, insights.*, quality.*, smart_actions.*\n"
        "- New inputs (حسب الفكرة):\n"
        "  - يتم تحديدها لاحقًا بالاستناد إلى محتوى الـ intent.\n"
    )
    md.append("")
    md.append("### 3.2 Data Outputs")
    md.append("")
    md.append(
        "- New reports/design docs under `reports/architecture/`.\n"
        "- احتمالية إضافة مخرجات إلى:\n"
        "  - ai/memory/offline/patterns/\n"
        "  - ai/memory/lessons/\n"
        "  - config/ (تعديلات مقترحة، وليست تلقائية).\n"
    )
    md.append("")

    md.append("## 4. KPIs & Monitoring")
    md.append("")
    md.append(
        "- **Design Coverage**     : عدد الـ intents المعالجة / إجمالي intents.\n"
        "- **Actionability**       : عدد الـ lessons/actionables الناتجة عن هذا التصميم.\n"
        "- **Integration Readiness**: وضوح نقاط الربط مع الـ Golden Pipeline والذاكرة.\n"
    )
    md.append("")

    md.append("## 5. Next Engineering Steps")
    md.append("")
    md.append(
        "1. مراجعة هذا التصميم يدويًا.\n"
        "2. تحويل المكوّنات المقترحة إلى سكربتات فعلية (.py + .sh) داخل hyper-factory.\n"
        "3. تحديث `config/agents.yaml` و/أو `config/factory.yaml` يدويًا عند اعتماد التصميم.\n"
        "4. ربط العمال الجدد مع الذاكرة والتقارير حسب الحاجة.\n"
    )
    md.append("")

    md.append("## 6. Open Questions")
    md.append("")
    md.append(
        "- ما هو نطاق هذا الـ intent بدقة (batch/offline/real-time)؟\n"
        "- ما هو مستوى المخاطرة المقبول عند تشغيل هذا النظام؟\n"
        "- هل يحتاج النظام إلى تكامل مع SmartFriend Suite لاحقًا؟\n"
    )
    md.append("")

    return "\n".join(md)


def write_text(path: str, text: str) -> None:
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def main() -> None:
    print(f"📁 ROOT        : {ROOT}")
    print(f"📂 INTENTS_DIR : {INTENTS_DIR}")
    print(f"📂 ARCH_DIR    : {ARCH_DIR}")
    print("----------------------------------------")

    ensure_dirs()

    quality = load_quality_status()

    intents = [f for f in os.listdir(INTENTS_DIR) if f.endswith(".md")]
    if not intents:
        print("ℹ️ لا توجد ملفات intents في design/intents/ بعد. أنشئ ملفات .md ثم أعد التشغيل.")
        return

    for fname in intents:
        intent_path = os.path.join(INTENTS_DIR, fname)
        try:
            intent_info = read_intent(intent_path)
        except Exception as e:
            print(f"⚠️ تعذّر قراءة intent: {intent_path} ({e})")
            continue

        design_md = build_design_markdown(intent_path, intent_info, quality)

        base_name = os.path.splitext(fname)[0]
        out_path = os.path.join(ARCH_DIR, f"{base_name}_design.md")

        write_text(out_path, design_md)
        print(f"✅ تم توليد ملف التصميم: {out_path}")

    print("✅ انتهى System Architect Worker: تم بناء تصاميم معماريّة لكل intents المتاحة.")


if __name__ == "__main__":
    main()
