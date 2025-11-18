# 🏭 Hyper Factory

منصة تجريبية لبناء "عمال أذكياء" فوق Orchestrator + Memory + Knowledge + Feedback.

## المكونات

- `apps/backend_coach`: خدمة FastAPI على المنفذ 9090.
- `scripts/core`: سكربتات المصنع (ffactory، init، status، start/stop).
- `scripts/ai`: المهارات، العنكبوت، orchestrator الخاص بالـ LLM، القياسات.
- `config/`: ملف `orchestrator.yaml` وباقي ملفات التكوين.
- `logs/` و `reports/`: تبقى محليًا وغير مرفوعة إلى GitHub.

## التشغيل السريع

    ./scripts/core/ffactory.sh init
    ./scripts/core/ffactory.sh start backend_coach
    curl http://localhost:9090/api/health

## الرخصة

هذا مشروع تجريبي/تعليمي.
