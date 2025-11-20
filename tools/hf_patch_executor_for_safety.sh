#!/usr/bin/env bash
set -Eeuo pipefail

# تعديل الـ executor لاستخدام الـ wrapper الآمن

BACKUP_FILE="hf_auto_executor.sh.backup.$(date +%Y%m%d_%H%M%S)"
EXECUTOR_FILE="hf_auto_executor.sh"

if [[ ! -f "$EXECUTOR_FILE" ]]; then
    echo "❌ ملف الـ executor غير موجود: $EXECUTOR_FILE"
    exit 1
fi

# نسخ احتياطي
cp "$EXECUTOR_FILE" "$BACKUP_FILE"
echo "✅ تم إنشاء نسخة احتياطية: $BACKUP_FILE"

# البحث عن سطور SQLite واستبدالها
if grep -q "sqlite3.*factory.db" "$EXECUTOR_FILE"; then
    echo "🔧 تعديل الـ executor لاستخدام الـ wrapper الآمن..."
    
    # إنشاء نسخة معدلة
    cat > "${EXECUTOR_FILE}.new" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail

# Hyper Factory – Auto Executor (Safe Version)
# يستخدم SQLite Safe Runner لمنع مشاكل القفل

# استدعاء الـ wrapper الآن لجميع عمليات SQLite
export SAFE_RUNNER="./tools/hf_safe_sqlite_runner.sh"

# الباقي من الكود الأصلي مع تعديلات...
SCRIPT

    # إضافة الكود الأصلي مع التعديلات
    grep -v "#!/usr/bin/env bash" "$EXECUTOR_FILE" | \
    sed 's/sqlite3.*factory.db/$SAFE_RUNNER sqlite3 factory.db/g' >> "${EXECUTOR_FILE}.new"
    
    mv "${EXECUTOR_FILE}.new" "$EXECUTOR_FILE"
    chmod +x "$EXECUTOR_FILE"
    
    echo "✅ تم تعديل الـ executor بنجاح!"
else
    echo "ℹ️  لم يتم العثور على استدعاءات sqlite3 مباشرة، قد تحتاج تعديل يدوي"
fi
