#!/usr/bin/env bash
# Hyper Factory – Smart Fix Plan Executor (v2)
# تركيز على:
# 1) إصلاح مخطط جدول tasks (type + family)
# 2) مزامنة agents من factory.db إلى knowledge.db
# 3) إصلاح رؤوس سكربتات الفحص المتقدم وتشغيل المعماري

set -u  # لا نستخدم set -e حتى لا يسقط السكربت عند أول خطأ فرعي

ROOT="/root/hyper-factory"
DB_FACTORY="$ROOT/data/factory/factory.db"
DB_KNOW="$ROOT/data/knowledge/knowledge.db"
DIAG_DIR="$ROOT/reports/diagnostics"

mkdir -p "$DIAG_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
LOG="$DIAG_DIR/hf_smart_fix_${TS}.log"

log() {
    echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"
}

log "=============================================="
log " Hyper Factory – Smart Fix Plan Executor (v2)"
log " ROOT=$ROOT"
log " LOG=$LOG"
log " TS=$TS"
log "=============================================="

# -----------------------------------------
# 1) فحص/إصلاح مخطط جدول المهام في factory.db
# -----------------------------------------
fix_tasks_schema() {
    if [ ! -f "$DB_FACTORY" ]; then
        log "⚠️ factory.db غير موجود: $DB_FACTORY"
        return
    fi

    if ! sqlite3 "$DB_FACTORY" ".schema tasks" >/dev/null 2>&1; then
        log "ℹ️ جدول tasks غير موجود في factory.db – لا يمكن الإصلاح الآلي."
        return
    fi

    log "ℹ️ PRAGMA table_info(tasks) قبل الإصلاح:"
    sqlite3 "$DB_FACTORY" "PRAGMA table_info(tasks);" | tee -a "$LOG"

    local has_type has_family
    has_type="$(sqlite3 "$DB_FACTORY" "PRAGMA table_info(tasks);" 2>/dev/null | awk -F'|' '$2=="type"{print "yes"}')"
    has_family="$(sqlite3 "$DB_FACTORY" "PRAGMA table_info(tasks);" 2>/dev/null | awk -F'|' '$2=="family"{print "yes"}')"

    if [ "$has_type" != "yes" ]; then
        log "🛠 إضافة عمود type إلى جدول tasks في factory.db..."
        if sqlite3 "$DB_FACTORY" "ALTER TABLE tasks ADD COLUMN type TEXT DEFAULT 'generic';" 2>>"$LOG"; then
            log "✅ تم إضافة العمود type بنجاح."
        else
            log "❌ فشل ALTER TABLE لإضافة العمود type – راجع المخطط يدويًا."
        fi
    else
        log "✅ العمود type موجود بالفعل."
    fi

    if [ "$has_family" != "yes" ]; then
        log "🛠 إضافة عمود family إلى جدول tasks في factory.db..."
        if sqlite3 "$DB_FACTORY" "ALTER TABLE tasks ADD COLUMN family TEXT DEFAULT 'general';" 2>>"$LOG"; then
            log "✅ تم إضافة العمود family بنجاح."
        else
            log "❌ فشل ALTER TABLE لإضافة العمود family – راجع المخطط يدويًا."
        fi
    else
        log "✅ العمود family موجود بالفعل."
    fi

    log "ℹ️ PRAGMA table_info(tasks) بعد محاولة الإصلاح:"
    sqlite3 "$DB_FACTORY" "PRAGMA table_info(tasks);" | tee -a "$LOG"
}

# --------------------------------------------------
# 2) مزامنة جدول agents من factory.db إلى knowledge.db
# --------------------------------------------------
sync_agents_from_factory() {
    if [ ! -f "$DB_FACTORY" ]; then
        log "⚠️ factory.db غير موجود: $DB_FACTORY"
        return
    fi
    if [ ! -f "$DB_KNOW" ]; then
        log "⚠️ knowledge.db غير موجود: $DB_KNOW"
        return
    fi

    if ! sqlite3 "$DB_FACTORY" ".schema agents" >/dev/null 2>&1; then
        log "ℹ️ جدول agents غير موجود في factory.db – لا يوجد مصدر للمزامنة."
        return
    fi
    if ! sqlite3 "$DB_KNOW" ".schema agents" >/dev/null 2>&1; then
        log "ℹ️ جدول agents غير موجود في knowledge.db – لا يمكن المزامنة الآلية."
        return
    fi

    local count_factory count_know_before
    count_factory="$(sqlite3 "$DB_FACTORY" "SELECT COUNT(*) FROM agents;" 2>/dev/null || echo "0")"
    count_know_before="$(sqlite3 "$DB_KNOW" "SELECT COUNT(*) FROM agents;" 2>/dev/null || echo "0")"

    log "ℹ️ عدد agents في factory.db: $count_factory"
    log "ℹ️ عدد agents في knowledge.db (قبل المزامنة): $count_know_before"

    if [ "$count_factory" = "0" ]; then
        log "⚠️ factory.db.agents فارغ – لا يوجد ما يُنسخ."
        return
    fi

    log "🚀 مزامنة agents من factory.db إلى knowledge.db باستخدام ATTACH (INSERT OR IGNORE)..."
    sqlite3 "$DB_KNOW" <<SQL 2>>"$LOG"
ATTACH '$DB_FACTORY' AS factory;
INSERT OR IGNORE INTO agents
SELECT * FROM factory.agents;
DETACH factory;
SQL

    local count_know_after
    count_know_after="$(sqlite3 "$DB_KNOW" "SELECT COUNT(*) FROM agents;" 2>/dev/null || echo "0")"
    log "ℹ️ عدد agents في knowledge.db (بعد المزامنة): $count_know_after"
}

# ----------------------------------------------------
# 3) إصلاح رؤوس سكربتات الفحص المتقدم (shebang header)
# ----------------------------------------------------
fix_script_header() {
    local file="$1"
    local label="$2"

    if [ ! -f "$file" ]; then
        log "⚠️ $label غير موجود: $file"
        return
    fi

    local first
    first="$(head -n 1 "$file" 2>/dev/null || echo "")"

    if printf '%s\n' "$first" | grep -q '^#!'; then
        log "✅ $label يحتوي على shebang صحيح – لا تعديل."
        return
    fi

    local backup="${file}.backup.${TS}"
    cp "$file" "$backup"
    log "🛠 إضافة shebang لملف $label. نسخة احتياطية: $backup"

    {
        echo '#!/usr/bin/env bash'
        echo "# auto-fixed header at ${TS} by hf_smart_fix_plan.sh"
        cat "$backup"
    } > "$file"

    chmod +x "$file" || true
    log "✅ تم إصلاح رأس سكربت $label."
}

# ----------------------------------------------------
# 4) تشغيل سكربتات المعماري بعد الإصلاح (إن وجدت)
# ----------------------------------------------------
run_post_fix_tools() {
    cd "$ROOT" || return

    if [ -x "./hf_db_architect_tasks_run.sh" ]; then
        log "🚀 تشغيل hf_db_architect_tasks_run.sh بعد إصلاح schema..."
        if ./hf_db_architect_tasks_run.sh >>"$LOG" 2>&1; then
            log "✅ hf_db_architect_tasks_run.sh اكتمل بدون خطأ حرج."
        else
            log "⚠️ hf_db_architect_tasks_run.sh أعاد خطأ – راجع اللوج، لكن السكربت الذكي لن يتوقف."
        fi
    else
        log "ℹ️ سكربت hf_db_architect_tasks_run.sh غير موجود أو غير قابل للتنفيذ."
    fi

    if [ -x "./hf_check_task_files.sh" ]; then
        log "🚀 تشغيل hf_check_task_files.sh لفحص اتساق المهام..."
        if ./hf_check_task_files.sh >>"$LOG" 2>&1; then
            log "✅ hf_check_task_files.sh اكتمل بدون خطأ حرج."
        else
            log "⚠️ hf_check_task_files.sh أعاد خطأ – راجع اللوج."
        fi
    else
        log "ℹ️ سكربت hf_check_task_files.sh غير موجود أو غير قابل للتنفيذ."
    fi
}

# ==========================
# تنفيذ الخطة بالترتيب
# ==========================
log "🔍 الخطوة 1: إصلاح مخطط جدول المهام في factory.db..."
fix_tasks_schema

log "🔍 الخطوة 2: مزامنة agents من factory.db إلى knowledge.db..."
sync_agents_from_factory

log "🔍 الخطوة 3: إصلاح رؤوس سكربتات الفحص المتقدم..."
fix_script_header "$ROOT/hf_comprehensive_health_check.sh" "hf_comprehensive_health_check.sh"
fix_script_header "$ROOT/hf_audit_advanced_infra.sh" "hf_audit_advanced_infra.sh"

log "🔍 الخطوة 4: تشغيل سكربتات المعماري بعد الإصلاح..."
run_post_fix_tools

# ملخص نهائي
log "=============================================="
log " ملخص سريع بعد الإصلاح:"
if [ -f "$DB_FACTORY" ]; then
    log "📊 مخطط tasks في factory.db (بعد):"
    sqlite3 "$DB_FACTORY" "PRAGMA table_info(tasks);" 2>/dev/null | tee -a "$LOG"
fi
if [ -f "$DB_KNOW" ]; then
    if sqlite3 "$DB_KNOW" ".schema agents" >/dev/null 2>&1; then
        local_agents_count="$(sqlite3 "$DB_KNOW" "SELECT COUNT(*) FROM agents;" 2>/dev/null || echo "err")"
        log "📊 عدد سجلات agents في knowledge.db (بعد): $local_agents_count"
    fi
fi
log "✅ انتهى hf_smart_fix_plan.sh (v2)"
log "📄 اللوج: $LOG"
