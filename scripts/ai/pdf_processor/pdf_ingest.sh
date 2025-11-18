#!/bin/bash
# pdf_ingest.sh - معالج PDF للمصنع

set -e

BASE_DIR="/root/hyper-factory"
PDF_DIR="$BASE_DIR/ai/pdfs"
TEXT_DIR="$BASE_DIR/ai/datasets/pdf_text"
CLEANED_DIR="$BASE_DIR/ai/datasets/cleaned_content"
KNOWLEDGE_DIR="$BASE_DIR/ai/datasets/knowledge_chunks"
LOG_FILE="$BASE_DIR/logs/pdf_processor.log"

# الألوان
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# إنشاء المجلدات والسجلات
mkdir -p "$TEXT_DIR" "$CLEANED_DIR" "$KNOWLEDGE_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[PDF Processor]${NC} $1"
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}❌ [PDF Processor]${NC} $1"
    echo "[$timestamp] ERROR: $1" >> "$LOG_FILE"
}

# التحقق من المتطلبات
check_requirements() {
    log "🔍 التحقق من المتطلبات..."
    
    if ! python3 -c "import pdfplumber" &>/dev/null; then
        error "pdfplumber غير مثبت"
        return 1
    fi
    
    if [ ! -d "$PDF_DIR" ]; then
        error "مجلد PDF غير موجود: $PDF_DIR"
        return 1
    fi
    
    log "✅ جميع المتطلبات جاهزة"
    return 0
}

# تحويل PDF إلى نص
pdf_to_text() {
    local pdf_file="$1"
    local output_file="$2"
    
    log "📄 تحويل PDF إلى نص: $(basename "$pdf_file")"
    
    python3 << SCRIPT
import pdfplumber
import os
import re

def clean_text(text):
    """تنظيف النص المستخرج"""
    if not text:
        return ""
    
    # إزالة المسافات الزائدة
    text = re.sub(r'\n\s*\n', '\n\n', text)
    text = re.sub(r' +', ' ', text)
    
    # إزالة الأحرف الخاصة
    text = re.sub(r'[^\u0600-\u06FF\u0750-\u077F\u08A0-\u08FFa-zA-Z0-9\s\.\,\!\?\:\;\(\)\-]', '', text)
    
    return text.strip()

try:
    with pdfplumber.open("$pdf_file") as pdf:
        full_text = ""
        
        for page_num, page in enumerate(pdf.pages, 1):
            text = page.extract_text()
            if text:
                cleaned_text = clean_text(text)
                if cleaned_text:
                    full_text += f"--- الصفحة {page_num} ---\n{cleaned_text}\n\n"
        
        # حفظ النص
        with open("$output_file", "w", encoding="utf-8") as f:
            f.write(full_text)
        
        print(f"✅ تم استخراج {len(pdf.pages)} صفحة من PDF")
        
except Exception as e:
    print(f"❌ خطأ في معالجة PDF: {e}")
    # محاولة بديلة باستخدام PyMuPDF
    try:
        import fitz
        doc = fitz.open("$pdf_file")
        full_text = ""
        
        for page_num in range(len(doc)):
            page = doc[page_num]
            text = page.get_text()
            if text:
                cleaned_text = clean_text(text)
                if cleaned_text:
                    full_text += f"--- الصفحة {page_num + 1} ---\n{cleaned_text}\n\n"
        
        with open("$output_file", "w", encoding="utf-8") as f:
            f.write(full_text)
        
        print(f"✅ تم استخراج {len(doc)} صفحة باستخدام PyMuPDF")
        doc.close()
        
    except Exception as e2:
        print(f"❌ فشل جميع محاولات استخراج النص: {e2}")
SCRIPT

    return $?
}

# تقسيم النص إلى chunks
split_text_to_chunks() {
    local text_file="$1"
    local base_name="$2"
    
    log "✂️ تقسيم النص إلى chunks: $(basename "$text_file")"
    
    python3 << SCRIPT
import os
import re

def split_into_chunks(text, chunk_size=1000, overlap=100):
    """تقسيم النص إلى chunks متداخلة"""
    words = text.split()
    chunks = []
    
    for i in range(0, len(words), chunk_size - overlap):
        chunk = ' '.join(words[i:i + chunk_size])
        if len(chunk.strip()) > 50:  # تجاهل chunks الصغيرة جداً
            chunks.append(chunk)
    
    return chunks

try:
    with open("$text_file", "r", encoding="utf-8") as f:
        content = f.read()
    
    if not content.strip():
        print("❌ الملف النصي فارغ")
        exit(1)
    
    # تقسيم المحتوى
    chunks = split_into_chunks(content)
    
    # حفظ ال chunks
    chunk_count = 0
    for i, chunk in enumerate(chunks):
        if chunk.strip():
            chunk_file = f"$KNOWLEDGE_DIR/${base_name}_pdf_chunk_{i:03d}.txt"
            with open(chunk_file, "w", encoding="utf-8") as f:
                f.write(chunk)
            chunk_count += 1
    
    print(f"✅ تم إنشاء {chunk_count} chunk معرفي")
    
except Exception as e:
    print(f"❌ خطأ في تقسيم النص: {e}")
    exit(1)
SCRIPT

    return $?
}

# المعالجة الرئيسية
process_pdfs() {
    log "🚀 بدء معالجة ملفات PDF..."
    
    # التحقق من وجود ملفات PDF
    pdf_files=("$PDF_DIR"/*.pdf)
    if [ ${#pdf_files[@]} -eq 0 ]; then
        log "ℹ️ لا توجد ملفات PDF في $PDF_DIR"
        log "📁 ضع ملفات PDF في: $PDF_DIR"
        return 0
    fi
    
    local processed=0
    local failed=0
    
    for pdf_file in "${pdf_files[@]}"; do
        if [ ! -f "$pdf_file" ]; then
            continue
        fi
        
        local base_name=$(basename "$pdf_file" .pdf)
        local text_file="$TEXT_DIR/${base_name}.txt"
        local cleaned_file="$CLEANED_DIR/${base_name}_pdf.txt"
        
        log "🔄 معالجة: $(basename "$pdf_file")"
        
        # تحويل PDF إلى نص
        if pdf_to_text "$pdf_file" "$text_file"; then
            # نسخ إلى مجلد المحتوى المنظف
            cp "$text_file" "$cleaned_file"
            
            # تقسيم إلى chunks
            if split_text_to_chunks "$text_file" "$base_name"; then
                log "✅ تم معالجة $(basename "$pdf_file") بنجاح"
                ((processed++))
            else
                error "فشل تقسيم النص: $(basename "$pdf_file")"
                ((failed++))
            fi
        else
            error "فشل تحويل PDF: $(basename "$pdf_file")"
            ((failed++))
        fi
    done
    
    log "📊 النتائج: $processed ملفات تمت معالجتها بنجاح, $failed فشل"
    
    # تحديث إحصائيات المصنع
    update_factory_stats
}

update_factory_stats() {
    log "📊 تحديث إحصائيات المصنع..."
    
    # محاولة تحديث API
    if curl -s http://localhost:9090/api/health > /dev/null 2>&1; then
        curl -s http://localhost:9090/api/knowledge/stats > /dev/null 2>&1
        log "✅ تم تحديث إحصائيات المصنع"
    else
        log "⚠️ API غير متاح - سيتم تحديث الإحصائيات عند التشغيل التالي"
    fi
}

# العرض التقديمي
show_stats() {
    local total_chunks=$(find "$KNOWLEDGE_DIR" -name "*pdf_chunk*" -type f 2>/dev/null | wc -l)
    local total_pdfs=$(find "$PDF_DIR" -name "*.pdf" -type f 2>/dev/null | wc -l)
    
    echo ""
    echo -e "${GREEN}🎯 إحصائيات معالج PDF${NC}"
    echo "=========================================="
    echo -e "📁 ملفات PDF: $total_pdfs"
    echo -e "🧠 القطع المعرفية من PDF: $total_chunks"
    echo -e "📊 السجلات: $LOG_FILE"
    echo ""
    echo -e "${YELLOW}💡 لوضع ملفات PDF:${NC}"
    echo -e "   cp /path/to/your/file.pdf $PDF_DIR/"
    echo ""
}

# التنفيذ الرئيسي
main() {
    echo -e "${GREEN}🏭 مصنع العمال الأذكياء - معالج PDF${NC}"
    echo "=========================================="
    
    if ! check_requirements; then
        exit 1
    fi
    
    process_pdfs
    show_stats
}

# إذا تم استدعاء السكريبت مباشرة
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
