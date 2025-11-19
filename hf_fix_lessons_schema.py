#!/usr/bin/env python3
"""
إصلاح مشكلة schema الدروس في hf_manager_dashboard.py
"""

import sys
from pathlib import Path

def fix_lessons_schema():
    """إصلاح مشكلة الحقول المفقودة في بيانات الدروس"""
    
    dashboard_file = Path("tools/hf_manager_dashboard.py")
    
    if not dashboard_file.exists():
        print(f"❌ ملف {dashboard_file} غير موجود!")
        return False
    
    # قراءة المحتوى الحالي
    with open(dashboard_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    print("🔧 إصلاح مشكلة schema الدروس...")
    
    # البحث عن السطر الذي يسبب المشكلة (السطر 246)
    problem_line = "f\"[{idx}] id={l['id']} | priority={l['priority']} | date={l['date']}\""
    
    if problem_line in content:
        # استبدال السطر بالمصحح
        fixed_line = "f\"[{idx}] file={l['file']} | priority={l.get('priority', 'medium')} | title={l.get('title', 'بدون عنوان')}\""
        content = content.replace(problem_line, fixed_line)
        print("✅ تم إصلاح سطر عرض الدروس")
    else:
        print("⚠️ لم أجد السطر المسبب للمشكلة")
    
    # البحث عن السطر الآخر المشابه
    problem_line2 = "f\"    title: {l['title']}\""
    if problem_line2 in content:
        fixed_line2 = "f\"    title: {l.get('title', 'بدون عنوان')}\""
        content = content.replace(problem_line2, fixed_line2)
        print("✅ تم إصلاح سطر العنوان الثاني")
    
    # حفظ الملف المحدث
    backup_file = dashboard_file.with_suffix('.py.backup2')
    with open(backup_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ تم إنشاء نسخة احتياطية: {backup_file}")
    
    # كتابة الملف الأصلي
    with open(dashboard_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ تم إصلاح مشكلة schema الدروس!")
    return True

if __name__ == "__main__":
    if fix_lessons_schema():
        print("\n🎯 الآن جرب تشغيل Manager Dashboard مرة أخرى:")
        print("   ./hf_run_manager_dashboard.sh")
    else:
        print("\n❌ فشل الإصلاح!")
        sys.exit(1)
