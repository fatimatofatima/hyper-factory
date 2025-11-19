# Offline Learner Architecture

هدف الفكرة:
- بناء طبقة تعلّم Offline تعتمد على ai/memory/messages.jsonl
- استخراج أنماط الأيام، الفشل، والاستقرار
- إنتاج sessions/patterns/lessons يمكن استخدامها لاحقاً في Smart Trainer أو Debug Expert

المتطلبات:
- لا تعديل مباشر على config/ أو data/ بدون مراجعة بشرية
- العمل فوق Golden Pipeline الحالي بدون تعطيله
