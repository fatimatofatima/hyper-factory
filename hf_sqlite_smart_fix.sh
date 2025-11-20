#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

ROOT_DIR="/root/hyper-factory"
DB_PATH="$ROOT_DIR/data/factory/factory.db"

log()    { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
info()   { log "ℹ️  $*"; }
warn()   { log "⚠️  $*"; }
error()  { log "❌ $*"; }
success(){ log "✅ $*"; }

main() {
  log "════════ Hyper Factory – SQLite Smart Fix ════════"

  # 0) التحقق من المسار
  if [[ ! -d "$ROOT_DIR" ]]; then
    error "ROOT_DIR غير موجود: $ROOT_DIR"
    exit 1
  fi
  cd "$ROOT_DIR"

  # 1) تشخيص سريع
  info "تشخيص الحالة الأولية..."
  if [[ ! -f "$DB_PATH" ]]; then
    error "قاعدة البيانات غير موجودة: $DB_PATH"
    exit 1
  fi

  info "حجم قاعدة البيانات:"
  du -h "$DB_PATH" || true

  info "العمليات المرتبطة بـ hyper-factory (قبل الإيقاف):"
  ps aux | grep -E "(hf_safe_sqlite_runner|hf_auto_executor|hf_smart_turbo|hf_24_7|hf_advanced_executor_manager|hyper-factory)" | grep -v grep || true

  info "فحص lsof على factory.db (إن أمكن):"
  lsof "$DB_PATH" 2>/dev/null || echo "ℹ️  لا توجد عملية ظاهرة عبر lsof على factory.db"

  # 2) إيقاف كل العمليات التي تضغط على factory.db
  info "إيقاف العمليات المرتبطة بقاعدة البيانات..."
  # أنماط معروفة
  PATTERNS=(
    "hf_safe_sqlite_runner.sh"
    "hf_auto_executor.sh"
    "hf_smart_turbo.sh"
    "hf_24_7"
    "hf_advanced_executor_manager.sh"
    "hf_24_7_autopilot"
    "factory.db"
  )

  for p in "${PATTERNS[@]}"; do
    info "محاولة إيقاف العمليات المطابقة للنمط: $p"
    pkill -f "$p" 2>/dev/null || true
  done

  # انتظار تفريغ القفل
  info "انتظار تحرير القفل من factory.db..."
  for i in {1..10}; do
    if lsof "$DB_PATH" >/dev/null 2>&1; then
      warn "ما زال هناك عمليات ماسكة الملف (محاولة $i/10)، الانتظار 2 ثانية..."
      sleep 2
    else
      success "لا توجد عمليات ماسكة factory.db الآن."
      break
    fi
  done

  if lsof "$DB_PATH" >/dev/null 2>&1; then
    warn "بعد المحاولات ما زال هناك Process ماسك factory.db – سيتم المتابعة، لكن قد يظهر database is locked."
  fi

  # 3) صيانة SQLite
  if ! command -v sqlite3 >/dev/null 2>&1; then
    error "sqlite3 غير مثبت على النظام. يرجى تثبيته (apt install sqlite3) ثم إعادة تشغيل السكربت."
    exit 1
  fi

  info "تشغيل صيانة SQLite على factory.db..."
  set +e
  SQLITE_OUTPUT=$(sqlite3 "$DB_PATH" <<'SQL'
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA busy_timeout=5000;
VACUUM;
PRAGMA journal_mode;
PRAGMA synchronous;
PRAGMA busy_timeout;
SQL
  )
  SQLITE_RC=$?
  set -e

  if [[ $SQLITE_RC -ne 0 ]]; then
    error "فشل تنفيذ أوامر sqlite3 على factory.db (exit code=$SQLITE_RC)."
    echo "$SQLITE_OUTPUT"
    exit 1
  else
    success "تم تنفيذ أوامر صيانة SQLite بنجاح."
    info "مخرجات PRAGMA بعد الصيانة:"
    echo "$SQLITE_OUTPUT"
  fi

  # 4) إعادة تشغيل النظام بنمط محافظ
  info "تشغيل نمط محافظ: Executor واحد + Turbo واحد..."

  # تأكد من وجود سكربتات التشغيل
  if [[ ! -x "./tools/hf_safe_sqlite_runner.sh" ]]; then
    warn "ملف ./tools/hf_safe_sqlite_runner.sh غير موجود أو غير قابل للتنفيذ."
  fi

  if [[ ! -f "./hf_auto_executor.sh" ]]; then
    warn "ملف ./hf_auto_executor.sh غير موجود."
  fi

  if [[ ! -f "./hf_smart_turbo.sh" ]]; then
    warn "ملف ./hf_smart_turbo.sh غير موجود."
  fi

  # تشغيل executor واحد فقط
  if [[ -x "./tools/hf_safe_sqlite_runner.sh" && -f "./hf_auto_executor.sh" ]]; then
    info "تشغيل Executor متوازن واحد..."
    nohup ./tools/hf_safe_sqlite_runner.sh ./hf_auto_executor.sh > logs/executor_opt_1.log 2>&1 &
    success "تم تشغيل executor_opt_1 (PID=$!)."
  else
    warn "تخطي تشغيل executor_opt_1 لعدم توفر السكربتات المطلوبة."
  fi

  # تشغيل Turbo واحد فقط
  if [[ -x "./tools/hf_safe_sqlite_runner.sh" && -f "./hf_smart_turbo.sh" ]]; then
    info "تشغيل smart_turbo واحد..."
    nohup ./tools/hf_safe_sqlite_runner.sh ./hf_smart_turbo.sh > logs/turbo_opt.log 2>&1 &
    success "تم تشغيل turbo_opt (PID=$!)."
  else
    warn "تخطي تشغيل smart_turbo لعدم توفر السكربتات المطلوبة."
  fi

  # 5) تقرير بعد إعادة التشغيل
  info "انتظار 10 ثوانٍ قبل التقرير النهائي..."
  sleep 10

  info "العمليات المرتبطة بـ hyper-factory (بعد الإصلاح):"
  ps aux | grep -E "(hf_safe_sqlite_runner|hf_auto_executor|hf_smart_turbo|hf_24_7|hf_advanced_executor_manager|hyper-factory)" | grep -v grep || true

  if [[ -x "./tools/hf_db_lock_report.sh" ]]; then
    info "تشغيل hf_db_lock_report.sh لمراجعة حالة database is locked..."
    ./tools/hf_db_lock_report.sh || true
  else
    warn "hf_db_lock_report.sh غير موجود – تخطي تقرير القفل."
  fi

  success "انتهى سكربت Hyper Factory – SQLite Smart Fix."
}

main "$@"
