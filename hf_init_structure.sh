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

- تعريف الدور (Role & Responsibilities)
- تعريف الـ pipelines المرتبطة
- خرائط التكامل مع data_lakehouse و knowledge و feedback
EOR
    echo "[+] created ${README_PATH}"
  fi
done

# 2) data_models / feedback / evaluation / crawler / knowledge / requirements
mkdir -p data_models feedback evaluation crawler knowledge

if [[ ! -f "data_models/user_state.py" ]]; then
  cat > data_models/user_state.py <<'EOPY'
"""
نموذج حالة المستخدم - Hyper Factory
"""
from pydantic import BaseModel
from typing import Dict, List
from datetime import datetime

class UserSkillState(BaseModel):
    user_id: str
    current_level: str
    skills: Dict[str, float]           # مهارة -> مستوى
    learning_path: List[str]
    last_activity: datetime
    performance_metrics: Dict[str, float]

    def update_skill(self, skill: str, level: float):
        self.skills[skill] = level
        self.last_activity = datetime.now()
EOPY
  echo "[+] created data_models/user_state.py"
fi

if [[ ! -f "feedback/README.md" ]]; then
  mkdir -p feedback/good feedback/bad feedback/rules
  cat > feedback/README.md <<'EOFB'
# Feedback System - Hyper Factory

- good/  : تعليقات إيجابية
- bad/   : تعليقات سلبية
- rules/ : قواعد تقييم الجودة
EOFB
  echo "[+] created feedback/ structure"
fi

if [[ ! -f "evaluation/README.md" ]]; then
  mkdir -p evaluation/tests evaluation/reports
  cat > evaluation/README.md <<'EOFE'
# Evaluation System - Hyper Factory

- tests/   : حزم الاختبار
- reports/ : تقارير التقييم
EOFE
  echo "[+] created evaluation/ structure"
fi

if [[ ! -f "crawler/README.md" ]]; then
  mkdir -p crawler/pipelines crawler/spiders
  cat > crawler/README.md <<'EOFC'
# Knowledge Crawler - Hyper Factory

- pipelines/ : بايبلاين الزحف
- spiders/   : العناكب (مصادر المعرفة)
EOFC
  echo "[+] created crawler/ structure"
fi

if [[ ! -f "knowledge/README.md" ]]; then
  mkdir -p knowledge/patterns knowledge/snippets
  cat > knowledge/README.md <<'EOFK'
# Knowledge Base - Hyper Factory

- patterns/ : أنماط معرفية
- snippets/ : مقتطفات وخلاصات
EOFK
  echo "[+] created knowledge/ structure"
fi

if [[ ! -f "requirements.txt" ]]; then
  cat > requirements.txt <<'EOFR'
# Hyper Factory - المتطلبات الأساسية
pyyaml>=6.0
requests>=2.28.0
python-dotenv>=0.19.0

# معالجة البيانات
pandas>=1.3.0
numpy>=1.21.0

# الأدوات المساعدة
tqdm>=4.62.0
colorama>=0.4.4
EOFR
  echo "[+] created requirements.txt"
fi

echo "[*] Init structure done."
