#!/usr/bin/env python3
"""
إصلاح مشكلة كشف الدروس في hf_manager_dashboard.py
"""

import sys
from pathlib import Path

def fix_lessons_detection():
    """إصلاح دالة load_lessons في hf_manager_dashboard.py"""
    
    dashboard_file = Path("tools/hf_manager_dashboard.py")
    
    if not dashboard_file.exists():
        print(f"❌ ملف {dashboard_file} غير موجود!")
        return False
    
    # قراءة المحتوى الحالي
    with open(dashboard_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # البحث عن دالة load_lessons الحالية
    if "def load_lessons(" not in content:
        print("❌ دالة load_lessons غير موجودة في الكود!")
        return False
    
    print("🔧 إصلاح دالة load_lessons...")
    
    # استبدال الدالة الحالية بدالة محسنة
    old_function = '''
def load_lessons(max_items=5):
    """تحميل الدروس من ai/memory/lessons/"""
    lessons_dir = ROOT / "ai" / "memory" / "lessons"
    lessons = []
    
    if lessons_dir.exists():
        lesson_files = list(lessons_dir.glob("*.json"))
        for lesson_file in lesson_files[:max_items]:
            try:
                with open(lesson_file, 'r', encoding='utf-8') as f:
                    lesson_data = json.load(f)
                    lessons.append({
                        'file': lesson_file.name,
                        'title': lesson_data.get('title', 'بدون عنوان'),
                        'description': lesson_data.get('description', ''),
                        'priority': lesson_data.get('priority', 'medium')
                    })
            except Exception as e:
                print(f"⚠️ خطأ في تحميل الدرس {lesson_file}: {e}")
    
    return lessons
'''
    
    new_function = '''
def load_lessons(max_items=10):
    """تحميل الدروس من ai/memory/lessons/"""
    lessons_dir = ROOT / "ai" / "memory" / "lessons"
    lessons = []
    
    if lessons_dir.exists():
        # البحث عن جميع ملفات JSON
        lesson_files = list(lessons_dir.glob("*.json"))
        print(f"🔍 اكتشاف {len(lesson_files)} ملف درس في {lessons_dir}")
        
        for lesson_file in lesson_files[:max_items]:
            try:
                with open(lesson_file, 'r', encoding='utf-8') as f:
                    lesson_data = json.load(f)
                    lesson_info = {
                        'file': lesson_file.name,
                        'title': lesson_data.get('title', lesson_data.get('lesson_title', 'بدون عنوان')),
                        'description': lesson_data.get('description', lesson_data.get('lesson_description', '')),
                        'priority': lesson_data.get('priority', 'medium')
                    }
                    # إذا كان الملف يحتوي على بيانات أساسية
                    if lesson_info['title'] != 'بدون عنوان':
                        lessons.append(lesson_info)
                    else:
                        print(f"⚠️ ملف بدون عنوان صالح: {lesson_file.name}")
            except Exception as e:
                print(f"⚠️ خطأ في تحميل الدرس {lesson_file}: {e}")
    
    return lessons
'''
    
    # استبدال الدالة
    if old_function in content:
        content = content.replace(old_function, new_function)
        print("✅ تم استبدال دالة load_lessons القديمة")
    else:
        print("⚠️ لم أجد الدالة القديمة بنفس التنسيق، سأبحث عن نمط مختلف...")
        # البحث عن الدالة بأي تنسيق
        import re
        pattern = r'def load_lessons\(.*?\):.*?return lessons'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            content = content.replace(match.group(0), new_function)
            print("✅ تم استبدال دالة load_lessons (بنمط مختلف)")
        else:
            print("❌ لم أستطع العثور على دالة load_lessons لاستبدالها")
            return False
    
    # حفظ الملف المحدث
    backup_file = dashboard_file.with_suffix('.py.backup')
    with open(backup_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ تم إنشاء نسخة احتياطية: {backup_file}")
    
    # كتابة الملف الأصلي
    with open(dashboard_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ تم تحديث hf_manager_dashboard.py بنجاح!")
    return True

if __name__ == "__main__":
    if fix_lessons_detection():
        print("\n🎯 الآن جرب تشغيل Manager Dashboard:")
        print("   ./hf_run_manager_dashboard.sh")
        print("\n📊 المتوقع في التقرير الجديد:")
        print("   'تم اكتشاف X درس في ai/memory/lessons/'")
    else:
        print("\n❌ فشل الإصلاح!")
        sys.exit(1)
