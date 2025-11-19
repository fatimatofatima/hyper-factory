#!/usr/bin/env python3
"""
إصلاح هيكل جداول قاعدة المعرفة
"""

import sqlite3
import os

def fix_debug_solutions_table():
    db_path = 'data/knowledge/knowledge.db'
    
    if not os.path.exists(db_path):
        print("❌ قاعدة المعرفة غير موجودة")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("🔧 إصلاح هيكل جدول debug_solutions...")
    
    # فحص الأعمدة الحالية
    cursor.execute("PRAGMA table_info(debug_solutions)")
    columns = [col[1] for col in cursor.fetchall()]
    print(f"📊 الأعمدة الحالية: {columns}")
    
    # إذا كانت الأعمدة الأساسية مفقودة، نعيد إنشاء الجدول
    required_columns = ['error_type', 'error_pattern', 'solution', 'confidence']
    missing_columns = [col for col in required_columns if col not in columns]
    
    if missing_columns:
        print(f"⚠️  الأعمدة المفقودة: {missing_columns}")
        
        # حفظ البيانات الحالية إذا كانت موجودة
        cursor.execute("SELECT COUNT(*) FROM debug_solutions")
        count = cursor.fetchone()[0]
        
        if count > 0:
            print("💾 حفظ البيانات الحالية...")
            cursor.execute("SELECT * FROM debug_solutions")
            old_data = cursor.fetchall()
        
        # إسقاط الجدول وإعادة إنشائه
        cursor.execute("DROP TABLE IF EXISTS debug_solutions")
        
        # إنشاء الجدول بالهيكل الصحيح
        cursor.execute('''
            CREATE TABLE debug_solutions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                error_type TEXT NOT NULL,
                error_pattern TEXT NOT NULL,
                solution TEXT NOT NULL,
                confidence INTEGER DEFAULT 80,
                usage_count INTEGER DEFAULT 0,
                success_count INTEGER DEFAULT 0,
                tags TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                last_used DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # إعادة إدخال البيانات إذا كانت موجودة
        if count > 0 and old_data:
            print("🔄 إعادة إدخال البيانات...")
            # هنا يمكنك معالجة البيانات القديمة حسب الحاجة
        
        # إدخال البيانات الأساسية
        debug_solutions = [
            ("ModuleNotFoundError", "No module named", 
             "قم بتثبيت المكتبة المطلوبة: pip install [package_name]", 95),
            ("SyntaxError", "invalid syntax", 
             "تحقق من الأقواس، النقطتين، المسافات البادئة، أو الأخطاء المطبعية", 90),
            ("NameError", "is not defined", 
             "تأكد من تعريف المتغير أو الدالة قبل استخدامها", 88),
            ("ImportError", "cannot import name", 
             "تحقق من هيكل الاستيراد وأسماء الملفات", 85),
            ("FileNotFoundError", "No such file or directory", 
             "تحقق من مسار الملف وأذونات الوصول", 92),
            ("PermissionError", "Permission denied", 
             "قم بتغيير أذونات الملف أو التشغيل كمسؤول", 87)
        ]
        
        for error_type, pattern, solution, confidence in debug_solutions:
            cursor.execute('''
                INSERT INTO debug_solutions 
                (error_type, error_pattern, solution, confidence)
                VALUES (?, ?, ?, ?)
            ''', (error_type, pattern, solution, confidence))
        
        print(f"✅ تم إصلاح الجدول وإضافة {len(debug_solutions)} سجل")
    
    else:
        print("✅ هيكل الجدول صحيح")
    
    conn.commit()
    
    # فحص النهائي
    cursor.execute("SELECT COUNT(*) FROM debug_solutions")
    final_count = cursor.fetchone()[0]
    cursor.execute("PRAGMA table_info(debug_solutions)")
    final_columns = [col[1] for col in cursor.fetchall()]
    
    print(f"📊 النتيجة النهائية: {final_count} سجل، الأعمدة: {final_columns}")
    
    conn.close()

if __name__ == "__main__":
    fix_debug_solutions_table()
