# System Design: Offline Learner Architecture

## Metadata
- Generated at   : 2025-11-19T07:22:12.875816Z
- Source intent  : offline_learner_architecture.md
- Tool           : hf_system_architect.py

## 1. Context & Intent

> **Original Intent (from design/intents):**

> # Offline Learner Architecture
>
> هدف الفكرة:
> - بناء طبقة تعلّم Offline تعتمد على ai/memory/messages.jsonl
> - استخراج أنماط الأيام، الفشل، والاستقرار
> - إنتاج sessions/patterns/lessons يمكن استخدامها لاحقاً في Smart Trainer أو Debug Expert
>
> المتطلبات:
> - لا تعديل مباشر على config/ أو data/ بدون مراجعة بشرية
> - العمل فوق Golden Pipeline الحالي بدون تعطيله

## 2. Current Golden Pipeline (Reference)

- **Name**      : Hyper Factory Golden Pipeline v0.1
- **Stages**    : ingestor_basic → processor_basic → analyzer_basic → reporter_basic
- **Memory**    : Online Memory + Offline Learner
- **Reporting** : basic_runs.log, summary_basic.*, semantic_*, smart_actions.*


### 2.1 Core Data Flow

```text
data/inbox/  →  data/raw/  →  data/processed/  →  data/semantic/  →  data/serving/
                          ↘ reports/basic_runs.log, data/report/summary_basic.*
                          ↘ ai/memory/messages.jsonl, insights.*, quality.*, smart_actions.*
```

### 2.2 Pipeline Health Snapshot

### Pipeline Health
- Status      : {'overall_status': 'GREEN', 'risk_level': 'LOW', 'summary': 'Status=GREEN, risk=LOW, success_rate=100.00%, total_runs=37, failed_runs=0', 'total_runs': 37, 'success_runs': 37, 'failed_runs': 0, 'success_rate': 1.0, 'steps_ranked': [{'name': 'ingestor_basic', 'count': 37, 'ok': 37, 'fail': 0, 'ok_rate': 1.0, 'fail_rate': 0.0}, {'name': 'processor_basic', 'count': 37, 'ok': 37, 'fail': 0, 'ok_rate': 1.0, 'fail_rate': 0.0}, {'name': 'analyzer_basic', 'count': 37, 'ok': 37, 'fail': 0, 'ok_rate': 1.0, 'fail_rate': 0.0}, {'name': 'reporter_basic', 'count': 37, 'ok': 37, 'fail': 0, 'ok_rate': 1.0, 'fail_rate': 0.0}], 'top_problems': []}
- Risk level  : UNKNOWN


## 3. Proposed System Components

- **High-level Objective**: ترجمة نية الـ intent إلى مكوّنات واضحة (workers, configs, reports).
- **Candidate Components** (مبدئية):
  - New worker(s) inside `tools/` أو `agents/`.
  - تكامل مع الذاكرة (ai/memory/) إن لزم.
  - تقارير إضافية تحت `reports/` أو `data/report/`.


### 3.1 Data Inputs

- Existing inputs:
  - data/raw/, data/processed/, data/semantic/
  - reports/basic_runs.log, data/report/summary_basic.*
  - ai/memory/messages.jsonl, insights.*, quality.*, smart_actions.*
- New inputs (حسب الفكرة):
  - يتم تحديدها لاحقًا بالاستناد إلى محتوى الـ intent.


### 3.2 Data Outputs

- New reports/design docs under `reports/architecture/`.
- احتمالية إضافة مخرجات إلى:
  - ai/memory/offline/patterns/
  - ai/memory/lessons/
  - config/ (تعديلات مقترحة، وليست تلقائية).


## 4. KPIs & Monitoring

- **Design Coverage**     : عدد الـ intents المعالجة / إجمالي intents.
- **Actionability**       : عدد الـ lessons/actionables الناتجة عن هذا التصميم.
- **Integration Readiness**: وضوح نقاط الربط مع الـ Golden Pipeline والذاكرة.


## 5. Next Engineering Steps

1. مراجعة هذا التصميم يدويًا.
2. تحويل المكوّنات المقترحة إلى سكربتات فعلية (.py + .sh) داخل hyper-factory.
3. تحديث `config/agents.yaml` و/أو `config/factory.yaml` يدويًا عند اعتماد التصميم.
4. ربط العمال الجدد مع الذاكرة والتقارير حسب الحاجة.


## 6. Open Questions

- ما هو نطاق هذا الـ intent بدقة (batch/offline/real-time)؟
- ما هو مستوى المخاطرة المقبول عند تشغيل هذا النظام؟
- هل يحتاج النظام إلى تكامل مع SmartFriend Suite لاحقًا؟

