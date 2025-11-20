#!/usr/bin/env bash
# Hyper Factory – Capacity Profile (Max Load)
# هذا الملف يُعرّف عدد العمال عند التشغيل بكامل الطاقة.

# عدد عمّال التنفيذ الرئيسيين (ingest/analysis/train/…)
export HF_EXECUTORS=16

# عدد عمّال Turbo (مهام ثقيلة/تحليل عميق)
export HF_TURBO_WORKERS=4

# حدود استرشادية فقط لمراقبة الأقفال (للـ reports والـ guard)
export HF_DB_LOCK_SOFT_LIMIT=200   # تحذيري (locks تقريبية في فترة تشغيل)
export HF_DB_LOCK_HARD_LIMIT=800   # حد خطر: عند تجاوزه خفّض الأعداد يدويًا
