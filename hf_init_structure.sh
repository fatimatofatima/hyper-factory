#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="/root/hyper-factory"
cd "$BASE_DIR"

echo "[*] Hyper Factory – init structure (non-destructive)"

# 1) Advanced agents folders
mkdir -p agents/debug_expert agents/system_architect agents/technical_coach agents/knowledge_spider

for AGENT in debug_expert system_architect technical_coach knowledge_spider; do
  README_PATH="agents/${AGENT}/README.md"
  if [[ ! -f "$README_PATH" ]]; then
    cat > "$README_PATH" <<EOR
# ${AGENT}

هذا المجلد مخصص لتعريف العامل المتقدم "${AGENT}" داخل Hyper Factory.

- تعريف الدور Role & Responsibilities
- تعريف الـ pipelines المرتبطة
- خرائط التكامل مع data_lakehouse و knowledge و feedback
EOR
    echo "[+] created $README_PATH"
  fi
done

# 2) data_models / user_state
mkdir -p data_models

if [[ ! -f "data_models/user_state.py" ]]; then
  cat > data_models/user_state.py <<'EOP'
"""
user_state.py

نموذج حالة المستخدم (Skill/Level/History) لـ Hyper Factory.
هذا ملف مبدئي (stub) لتوثيق واجهة النموذج فقط.
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional


@dataclass
class UserSkillState:
    user_id: str
    skills: Dict[str, float] = field(default_factory=dict)
    tracks: List[str] = field(default_factory=list)
    last_update: Optional[str] = None  # ISO 8601

    def to_dict(self) -> Dict:
        return {
            "user_id": self.user_id,
            "skills": self.skills,
            "tracks": self.tracks,
            "last_update": self.last_update,
        }
EOP
  echo "[+] created data_models/user_state.py"
fi

# 3) feedback system
mkdir -p feedback/good feedback/bad feedback/rules

if [[ ! -f "feedback/README.md" ]]; then
  cat > feedback/README.md <<'EOR'
# Feedback System

نظام feedback لتقييم أداء العوامل والمصنع:

- feedback/good/ : مخرجات ناجحة أو حالات نجاح واضحة.
- feedback/bad/  : مخرجات فاشلة أو حالات تحتاج تحسين.
- feedback/rules/: قواعد التقييم (scoring / heuristics / templates).
EOR
  echo "[+] created feedback/README.md"
fi

# 4) evaluation system
mkdir -p evaluation/tests evaluation/reports

if [[ ! -f "evaluation/README.md" ]]; then
  cat > evaluation/README.md <<'EOR'
# Evaluation System

نظام التقييم (Evaluation):

- evaluation/tests/   : تعريف حالات الاختبار والسيناريوهات.
- evaluation/reports/ : تقارير التقييم والجودة على مستوى العوامل والمصنع.
EOR
  echo "[+] created evaluation/README.md"
fi

# 5) crawler system
mkdir -p crawler/spiders crawler/pipelines

if [[ ! -f "crawler/README.md" ]]; then
  cat > crawler/README.md <<'EOR'
# Knowledge Crawler

طبقة زحف المعرفة (Knowledge Crawler):

- crawler/spiders/   : تعريف الزواحف لكل مصدر معرفة.
- crawler/pipelines/ : خطوط المعالجة من الزحف إلى التخزين في knowledge/.
EOR
  echo "[+] created crawler/README.md"
fi

# 6) knowledge base folders (files تبنى لاحقًا من الأنظمة)
mkdir -p knowledge/snippets knowledge/patterns

if [[ ! -f "knowledge/README.md" ]]; then
  cat > knowledge/README.md <<'EOR'
# Knowledge Base

قاعدة المعرفة لـ Hyper Factory:

- knowledge/snippets/ : مقاطع معرفة قصيرة (rules, hints, examples).
- knowledge/patterns/ : أنماط متقدمة وتحليلات مهيكلة.
EOR
  echo "[+] created knowledge/README.md"
fi

# 7) requirements.txt (للمشروع نفسه فقط إن لم يكن موجودًا)
if [[ ! -f "requirements.txt" ]]; then
  cat > requirements.txt <<'EOR'
# Hyper Factory – Python dependencies (project-level)
# ملاحظة: هذا الملف لا يلمس أي venv خارجية، الهدف توثيق الحزم المطلوبة للمشروع.

# Core
pydantic>=2.0
pyyaml>=6.0

# Data / AI (adjust لاحقًا حسب الاحتياج الفعلي)
numpy
pandas

# Database / SQLite tools
sqlalchemy

# Optional: logging / cli enhancements
rich
typer
EOR
  echo "[+] created requirements.txt"
fi

echo "[*] Init structure done."
