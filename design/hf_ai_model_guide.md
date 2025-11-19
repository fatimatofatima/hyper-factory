# Hyper Factory – دليل ثابت للنماذج (AI Model Guide)

> هذا الملف هو نقطة البداية لأي نموذج ذكاء اصطناعي يتعامل مع مشروع **Hyper Factory**.  
> الهدف: فهم الصورة العامة، معرفة ما هو موجود داخل الـ repo، وما هو مفقود عمدًا (أسرار، إعدادات إنتاج)، وكيفية البناء على الوضع الحالي بدون تخريب.

---

## 1) تعريف Hyper Factory (منظور أعمال)

Hyper Factory = “مصنع عمال آليين” (Agents) يقوم بـ:

- استقبال مهام / ملفات / حالات من النظام الأكبر (SmartFriend / ffactory أو غيره).
- تمريرها عبر خط أنابيب (Pipeline) بسيط:
  1. **Ingestor**: إدخال البيانات.
  2. **Processor**: معالجة أولية وتنظيف.
  3. **Analyzer**: تحليل دلالي / سياقي.
  4. **Reporter**: إنتاج مخرجات (تقارير، ملخصات، مؤشرات أداء).

- تخزين:
  - ذاكرة تشغيلية (ai/memory/*).
  - معرفة منظمة (data/knowledge/knowledge.db).
  - تقارير إدارة وصحة (reports/*).

هذا المشروع جزء من منظومة أكبر، لكنه يمكن أن يعمل كمصنع مستقل لتجارب “ذكاء اصطناعي تشغيلي” (Operational AI Factory).

---

## 2) مصادر الحقيقة للنموذج

عند قراءة المشروع، **لا تفترض** أن صورة السياق كاملة في ملف واحد.  
ترتيب القراءة الموصى به لأي نموذج:

1. هذا الملف: `design/hf_ai_model_guide.md`  
2. آخر Snapshot في:  
   `reports/ai/*_ai_context_snapshot.md`  
   - يحتوي على:
     - حالة git (الفروع / الريموت).
     - بنية المجلدات الفعلية على السيرفر.
     - Snapshot من قاعدة المعرفة `knowledge_items`.
     - ملخص تقارير الإدارة الأخيرة.
3. تقارير الإدارة:  
   `reports/management/*_manager_daily_overview.*`
4. إعدادات المصنع:  
   - `config/agents.yaml`
   - `config/factory.yaml`
   - `config/factory_manifest.yaml`
   - `config/apps.yaml`
5. ملفات الدور والعمال:  
   - `config/roles.json`
   - `agents/*.py` + `agents/*.sh`
6. ذاكرة ونتائج سابقة:
   - `ai/memory/*`
   - `data/semantic/*`
   - `data/report/*`
   - `data/serving/*`

بهذا الترتيب، النموذج يحصل على “صورة تشغيلية” قبل اقتراح أي تغييرات.

---

## 3) ما يوجد داخل الـ Repository حاليًا (ملخص بنية)

> التفاصيل الدقيقة تُستخرج من آخر Snapshot (`reports/ai/*_ai_context_snapshot.md`).  
> الملخص هنا ثابت على مستوى البنية، لا على مستوى المحتوى.

### 3.1 مجلدات الكود الأساسية

- `apps/backend_coach/`
  - REST API أو خدمة خلفية (Backend) لإدارة المهارات / الـ Skills.
  - ملفات مهمة:
    - `main.py`
    - `skills_api.py`
    - `requirements.txt`
    - `run.sh`
- `agents/`
  - عمال الـ Pipeline الأساسية:
    - `ingestor_basic.*`
    - `processor_basic.*`
    - `analyzer_basic.*`
    - `reporter_basic.*`
- `scripts/`
  - سكربتات إدارة وتشغيل المصنع:
    - `scripts/core/*.sh` (orchestrator, health_monitor, start_app, init_factory, …)
    - `scripts/ai/*.py / *.sh` (rag_engine, knowledge_spider, skills_manager, …)
- `config/`
  - تعريف المصنع والوكلاء:
    - `agents.yaml`
    - `factory.yaml`
    - `factory_manifest.yaml`
    - `apps.yaml`
    - `orchestrator.yaml`
    - `roles.json`
- `tools/`
  - أدوات مساعدة:
    - `tools/hf_import_agent_levels_to_knowledge.py` (استيراد مستويات العمال إلى knowledge.db)
    - أدوات أخرى حسب التحديثات.

### 3.2 مجلدات البيانات والذاكرة

- `ai/memory/`
  - حالات، رسائل، جودة، دروس، أنماط:
    - `debug_cases.json`
    - `insights.*`
    - `quality.*`
    - `smart_actions.*`
    - `messages.jsonl`
    - إلخ.
- `ai/pdfs/`
  - ملفات مرجعية (مثل كتيبات DeepSeek بالعربية).
- `data/`
  - `data/raw/`         : ملفات خام.
  - `data/processed/`   : ملفات بعد التحليل الأولي.
  - `data/semantic/`    : مؤشرات واستنتاجات دلالية.
  - `data/report/`      : ملخصات نتائج.
  - `data/serving/`     : بيانات جاهزة للاستهلاك.
  - `data/knowledge/knowledge.db` : قاعدة المعرفة (جدول `knowledge_items`).

### 3.3 التقارير والإدارة

- `reports/ai/`
  - ملفات Snapshot للسياق (التي ينشئها `hf_export_ai_context.sh`).
- `reports/management/`
  - تقارير Manager اليومية (`*_manager_daily_overview.*`).
- `reports/architecture/`
  - تصميمات معمارية (مثل: `offline_learner_architecture_design.md`).
- `reports/config_changes/`
  - Diff في ملفات config + ملخص دروس.

---

## 4) ما هو موجود في قاعدة المعرفة (knowledge.db)

الجدول الأساسي: `knowledge_items`  
الأعمدة (كما ظهرت في الـ Snapshot):

- `id` (INTEGER, AUTOINCREMENT)
- `source_id` (INTEGER أو معرف مصدر)
- `item_type` (TEXT)
- `item_key` (TEXT)
- `title` (TEXT)
- `body` (TEXT)
- `importance` (REAL)
- `tags` (TEXT)
- `created_at` (TEXT)
- `updated_at` (TEXT)
- `meta_json` (TEXT)

أنواع رئيسية مستخدمة حاليًا (تتغيّر مع التقدّم، لكنها موجودة في الـ Snapshot):

- `agent_level`      : تعريف مستويات العمال (ingestor_basic, …).
- `curriculum_phase` : مراحل تطوّر وتشغيل المصنع.
- `kpi`              : مؤشرات أداء رئيسية.
- `lesson`           : دروس مستفادة / أفعال مقترحة.

النموذج يجب أن يتعامل مع هذه القيم كـ **Source of Truth** لمستوى العمال، المراحل، والدروس.

---

## 5) سياسات الأسرار والبيانات الحساسة

مهم جدًا لأي نموذج:

1. **ما لن تجده في الـ repo (عمداً):**
   - Tokens (Telegram, GitHub, OpenAI, …).
   - كلمات سر قواعد بيانات إنتاجية.
   - أي بيانات شخصية أو حساسة عن المستخدم.
   - إعدادات Production الخاصة بالخوادم الأخرى.

2. **أين تعيش هذه الأسرار؟**
   - خارج repo، غالبًا في:
     - ملفات `.env` محلية.
     - إعدادات systemd / environment.
     - خزائن خارجية (ليست ضمن hyper-factory).

3. **قواعد ثابتة للنموذج:**
   - لا تقترح إضافة Tokens أو كلمات سر مباشرة داخل:
     - `config/*.yaml`, `*.json`, `*.py`, `*.sh` أو أي ملف تحت git.
   - استخدم دائمًا:
     - متغيرات بيئة (ENV VARS) أو ملفات `.env` غير متتبعة (ignored).
   - اعتبر أن أي حقل “مفقود” له علاقة بالتوكنات أو السرية = مخفي عن عمد، وليس “نسيان” من المالك.

---

## 6) حالة الـ Git وسياسة الفروع

السياسة الحالية (حسب الـ Snapshots):

- Git Remote:
  - `origin` → مستودع GitHub: `fatimatofatima/hyper-factory`
- الفروع:
  - `main`   : نسخة مرجعية قديمة (baseline تاريخي).
  - `master` : الفرع النشط الفعلي (جميع التغييرات الجديدة عليه).

قواعد ثابتة:

1. أي سكربت مزامنة (مثل `hf_sync_code.sh`) يعمل على **master فقط** ويحافظ على `main` كمرجع.
2. لا يتم عمل Force-Push أو Rebase تدميري على `main` بدون قرار صريح من المالك.
3. المزامنة تفضّل:
   - الأكواد والسكربتات.
   - لا ترفع بيانات تشغيل حساسة (يمكن تغيير سياسة الاختيار لاحقًا يدويًا من المالك فقط).

---

## 7) سكربتات البنية التحتية (Infra Helpers)

سكربتات أساسية يجب أن يفهمها أي نموذج:

1. `hf_sync_code.sh`
   - مزامنة الكود من السيرفر إلى GitHub على `master`.
   - يحترم سياسة “عدم لمس main”.
2. `hf_backup_snapshot.sh`
   - إنشاء نسخة احتياطية كاملة:
     - `/root/hf_backups/hyper-factory_full_YYYYMMDDTHHMMSSZ.tar.zst`
3. `hf_export_ai_context.sh`
   - إنشاء تقرير Snapshot سياقي في:
     - `reports/ai/*_ai_context_snapshot.md`
   - هذا التقرير هو نقطة الدخول التقني لأي نموذج جديد لفهم الحالة الفعلية على السيرفر.

---

## 8) كيف يجب أن يبدأ أي نموذج جديد عمليًا؟

عند استلام مهمة تتعلق بـ Hyper Factory:

1. اقرأ هذا الملف: `design/hf_ai_model_guide.md`.
2. افتح أحدث ملف في `reports/ai/*_ai_context_snapshot.md`:
   - افهم:
     - الفروع النشطة.
     - بنية المشروع.
     - أنواع عناصر المعرفة الموجودة.
     - تقارير الإدارة الأخيرة.
3. راجع:
   - `reports/management/*_manager_daily_overview.*`
   - يعطيك KPIs + توصيات مدير المصنع.
4. اطلع على:
   - `config/agents.yaml`
   - `config/factory.yaml`
   - `config/roles.json`
5. اربط الصورة مع:
   - `agents/*.py` + `scripts/core/*.sh`.
6. **قبل** اقتراح تعديلات:
   - احترم سياسة الأسرار (لا تضف توكنات للريبو).
   - لا تحذف سكربتات أو تقارير.
   - لا تغيّر سلوك backup, sync, snapshot إلا بطلب صريح من المالك.

---

## 9) فجوات معروفة / TODO للنماذج

نقاط ناقصة متعمّد تركها مفتوحة للتطوير، ويمكن لأي نموذج العمل عليها بعد موافقة المالك:

1. **Runbook تنفيذي موحّد:**
   - ملف (مثلاً: `design/hf_runbook_operations.md`) يشرح:
     - كيف يتم تشغيل المصنع يوميًا.
     - ترتيب تشغيل `run_basic_with_memory.sh` و `hf_run_*`.
     - سياسة الفشل وإعادة المحاولة.

2. **ربط الدروس بالمكوّنات فعليًا:**
   - الارتباط بين:
     - `knowledge_items` (type=lesson، curriculum_phase)
     - وملفات `config/agents.yaml` / `factory.yaml`.
   - عبر خطّة واضحة لاستخدام `hf_run_apply_lessons.sh`.

3. **تشغيل آلي مستقر (cron / systemd):**
   - تعريف رسمي (خارج الريبو) لكيفية:
     - تشغيل دورات المصنع تلقائيًا.
     - توليد تقارير Manager دوريًا.
     - توليد Snapshots سياقية جديدة باستمرار.

4. **ربط Hyper Factory مع منظومات أخرى (SmartFriend / ffactory):**
   - هذا الربط موجود في سكربتات/تصميمات أعلى مستوى، لكنه غير موثّق بالكامل هنا عمدًا.
   - أي تعديل في هذا الربط يجب أن يتم بالتنسيق مع المشروع الأكبر، وليس من داخل hyper-factory وحده.

---

## 10) مبادئ عامة للتعامل مع Hyper Factory

- الإضافة > الحذف:
  - فضّل إضافة سكربتات / تقارير / طبقات جديدة بدل حذف القديمة.
- التوثيق جزء من الكود:
  - أي تغيير جوهري في:
    - agents
    - config
    - pipeline
  - يجب أن ينعكس في:
    - هذا الملف (إذا كان تغيير في الصورة العامة).
    - أو في ملفات تصميم / تقارير جديدة.
- حافظ على:
  - تماسك `knowledge_items` (أنواع + مفاتيح واضحة).
  - تماسك سكربتات backup/sync/snapshot.

---

> هذا الملف لا يحتوي على أسرار ولا بيانات حساسة، ويمكن مشاركته مع أي نموذج أو نظام لتحميل “صورة المصنع” بدون تعريض النظام لأي مخاطر أمان.
