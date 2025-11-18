#!/bin/bash
# knowledge_spider.sh

set -e

BASE_DIR="$HOME/hyper-factory"
SPIDER_DIR="$BASE_DIR/ai/datasets"
LOGS_DIR="$BASE_DIR/logs/spider"

mkdir -p "$SPIDER_DIR"/{raw_content,cleaned_content,knowledge_chunks,spider_seeds}
mkdir -p "$LOGS_DIR"

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOGS_DIR/spider.log"
    echo "$1"
}

echo "🕸️ بدء تشغيل عنكبوت المعرفة..."
echo "=========================================="

# 1. إعداد البذور
setup_seeds() {
    log "🌱 إعداد البذور الأولية..."
    
    cat > "$SPIDER_DIR/spider_seeds/urls.txt" << 'URLS'
https://docs.python.org/3/tutorial/
https://fastapi.tiangolo.com/
https://docs.djangoproject.com/
https://realpython.com/
URLS
    
    log "✅ البذور جاهزة: $SPIDER_DIR/spider_seeds/urls.txt"
}

# 2. جلب المحتوى
fetch_content() {
    local url="$1"
    local domain=$(echo "$url" | cut -d'/' -f3)
    local output_dir="$SPIDER_DIR/raw_content/$domain"
    mkdir -p "$output_dir"
    
    local filename=$(echo "$url" | md5sum | cut -d' ' -f1)
    local output_file="$output_dir/${filename}.html"
    
    log "📥 جلب المحتوى من: $url"
    
    # استخدام wget أو curl
    if command -v wget &> /dev/null; then
        if wget -q --timeout=30 -O "$output_file" "$url" 2>/dev/null; then
            log "✅ تم الجلب باستخدام wget: $output_file"
            echo "$url" >> "$SPIDER_DIR/successful_fetches.txt"
            return 0
        fi
    fi
    
    if command -v curl &> /dev/null; then
        if curl -s --max-time 30 -o "$output_file" "$url" 2>/dev/null; then
            log "✅ تم الجلب باستخدام curl: $output_file"
            echo "$url" >> "$SPIDER_DIR/successful_fetches.txt"
            return 0
        fi
    fi
    
    log "❌ فشل الجلب: $url"
    echo "$url" >> "$SPIDER_DIR/failed_fetches.txt"
    return 1
}

# 3. تنظيف المحتوى
clean_content() {
    local input_file="$1"
    local output_dir="$SPIDER_DIR/cleaned_content"
    mkdir -p "$output_dir"
    
    local base_name=$(basename "$input_file" .html)
    local output_file="$output_dir/${base_name}.txt"
    
    log "🧹 تنظيف المحتوى: $input_file"
    
    if [ -f "$input_file" ]; then
        # استخراج النص الأساسي (محاكاة - في الواقع نستخدم lynx أو python)
        echo "🔗 المصدر: $input_file" > "$output_file"
        echo "📅 تم الجلب: $(date)" >> "$output_file"
        echo "==========================================" >> "$output_file"
        
        # محاولة استخراج النص من HTML
        if command -v lynx &> /dev/null; then
            lynx -dump "$input_file" >> "$output_file" 2>/dev/null
        else
            # بديل بسيط إذا lynx غير موجود
            grep -o '<title>[^<]*' "$input_file" | sed 's/<title>//' >> "$output_file" 2>/dev/null || true
            echo "📄 محتوى HTML (استخدم lynx لاستخراج أفضل)" >> "$output_file"
        fi
        
        log "✅ تم التنظيف: $output_file"
    else
        log "❌ ملف غير موجود: $input_file"
    fi
}

# 4. تقسيم إلى قطع
chunk_content() {
    local input_file="$1"
    local output_dir="$SPIDER_DIR/knowledge_chunks"
    mkdir -p "$output_dir"
    
    local base_name=$(basename "$input_file" .txt)
    
    log "✂️ تقسيم المحتوى: $input_file"
    
    if [ -f "$input_file" ]; then
        # تقسيم إلى قطع ~100 سطر
        split -d -l 100 "$input_file" "$output_dir/${base_name}_chunk_" 2>/dev/null || \
        cp "$input_file" "$output_dir/${base_name}_chunk_00"
        
        local chunk_count=$(ls "$output_dir/${base_name}_chunk_"* 2>/dev/null | wc -l)
        log "✅ تم إنشاء $chunk_count قطعة: $output_dir/${base_name}_chunk_*"
    fi
}

# 5. فحص الجودة
quality_check() {
    log "🔍 فحص جودة المعرفة المجمعة..."
    
    local total_chunks=$(find "$SPIDER_DIR/knowledge_chunks" -name "*chunk*" -type f 2>/dev/null | wc -l)
    local total_sources=$(find "$SPIDER_DIR/raw_content" -name "*.html" -type f 2>/dev/null | wc -l)
    
    log "📊 إحصائيات الجودة:"
    log "   - إجمالي القطع المعرفية: $total_chunks"
    log "   - إجمالي المصادر: $total_sources"
    log "   - القطع لكل مصدر: $((total_sources > 0 ? total_chunks / total_sources : 0))"
    
    if [ "$total_chunks" -gt 0 ]; then
        log "✅ جودة المعرفة: جيدة ($total_chunks قطعة)"
    else
        log "⚠️  جودة المعرفة: تحتاج تحسين"
    fi
}

# التنفيذ الرئيسي
main() {
    log "🕸️ بدء دورة جمع المعرفة..."
    
    setup_seeds
    
    # جلب المحتوى من البذور
    while IFS= read -r url; do
        if [ -n "$url" ]; then
            fetch_content "$url"
        fi
    done < "$SPIDER_DIR/spider_seeds/urls.txt"
    
    # معالجة المحتوى المجلوب
    for domain_dir in "$SPIDER_DIR/raw_content"/*; do
        if [ -d "$domain_dir" ]; then
            for html_file in "$domain_dir"/*.html; do
                if [ -f "$html_file" ]; then
                    clean_content "$html_file"
                fi
            done
        fi
    done
    
    # تقسيم المحتوى المنظف
    for text_file in "$SPIDER_DIR/cleaned_content"/*.txt; do
        if [ -f "$text_file" ]; then
            chunk_content "$text_file"
        fi
    done
    
    # فحص الجودة النهائي
    quality_check
    
    log "✅ اكتملت دورة جمع المعرفة!"
    
    # عرض النتائج
    echo ""
    echo "🎯 نتائج العنكبوت:"
    echo "   - القطع المعرفية: $(find "$SPIDER_DIR/knowledge_chunks" -name "*chunk*" -type f 2>/dev/null | wc -l)"
    echo "   - المصادر: $(find "$SPIDER_DIR/raw_content" -type d | tail -n +2 | wc -l)"
    echo "   - السجلات: $LOGS_DIR/spider.log"
}

main "$@"

# 6. تحديث إحصائيات المصنع
update_factory_stats() {
    local chunk_count=$(find "$SPIDER_DIR/knowledge_chunks" -name "*chunk*" -type f 2>/dev/null | wc -l)
    
    log "📊 تحديث إحصائيات المصنع: $chunk_count قطعة معرفية"
    
    # محاولة تحديث API إذا كان شغال
    if curl -s http://localhost:9090/api/health > /dev/null 2>&1; then
        log "✅ API شغال - سيتم تحديث الإحصائيات"
    else
        log "⚠️  API غير متاح - سيتم تحديث الإحصائيات محلياً"
    fi
}

# في نهاية main() نضيف:
update_factory_stats
