#!/bin/bash
echo "🚀 نشر النظام في بيئة الإنتاج..."

# 1. نسخ احتياطي
./hf_backup_snapshot.sh

# 2. تحديث الريبو
git pull origin master

# 3. فحص الصحة
./hf_master_dashboard.sh --quick

# 4. تشغيل الخدمات
systemctl enable hyper-factory
systemctl start hyper-factory

echo "✅ تم النشر بنجاح!"
