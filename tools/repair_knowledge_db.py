#!/usr/bin/env python3
"""
إصلاح هيكل قاعدة المعرفة
"""

import sqlite3
import os

def repair_database():
    db_path = "data/knowledge/knowledge.db"
    os.makedirs("data/knowledge", exist_ok=True)
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("🔧 يصلح هيكل قاعدة المعرفة...")
    
    # إسقاط الجداول القديمة إذا كانت موجودة
    cursor.execute("DROP TABLE IF EXISTS web_knowledge")
    cursor.execute("DROP TABLE IF EXISTS debug_solutions")
    cursor.execute("DROP TABLE IF EXISTS programming_patterns")
    
    # إنشاء الجداول بالهيكل الصحيح
    cursor.execute('''
        CREATE TABLE web_knowledge (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            url TEXT UNIQUE,
            source_type TEXT,
            category TEXT,
            difficulty TEXT,
            tags TEXT,
            content_length INTEGER,
            quality_score REAL DEFAULT 0.0,
            crawled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE debug_solutions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            error_pattern TEXT UNIQUE,
            solution TEXT,
            category TEXT,
            confidence_score REAL DEFAULT 0.0,
            usage_count INTEGER DEFAULT 0,
            success_rate REAL DEFAULT 0.0,
            last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE programming_patterns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pattern_name TEXT,
            pattern_description TEXT,
            code_example TEXT,
            use_cases TEXT,
            category TEXT,
            difficulty TEXT,
            source_url TEXT
        )
    ''')
    
    # إضافة بيانات أولية
    initial_solutions = [
        ('ModuleNotFoundError.*No module named', 
         'قم بتثبيت المكتبة: pip install <package_name>', 
         'import_issues', 0.95),
        ('SyntaxError.*invalid syntax', 
         'تحقق من: 1) الأقواس المغلقة 2) النقطتين بعد الشروط 3) المسافات البادئة', 
         'syntax_basics', 0.90),
        ('NameError.*is not defined', 
         'تأكد من: 1) تعريف المتغير قبل استخدامه 2) تهجئة الاسم بشكل صحيح', 
         'variable_scope', 0.88)
    ]
    
    for pattern, solution, category, confidence in initial_solutions:
        cursor.execute('''
            INSERT INTO debug_solutions 
            (error_pattern, solution, category, confidence_score)
            VALUES (?, ?, ?, ?)
        ''', (pattern, solution, category, confidence))
    
    conn.commit()
    conn.close()
    print("✅ تم إصلاح قاعدة المعرفة بنجاح")

if __name__ == "__main__":
    repair_database()
