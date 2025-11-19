#!/usr/bin/env python3
"""
إصلاح نظام المعرفة لـ Hyper-Factory - متوافق مع الهيكل الحقيقي
"""

import sqlite3
import os
import json
from datetime import datetime

class KnowledgeRepair:
    def __init__(self):
        self.db_path = "data/knowledge/knowledge.db"
        self.backup_dir = "data/knowledge/backups"
        os.makedirs(self.backup_dir, exist_ok=True)
    
    def create_backup(self):
        """إنشاء نسخة احتياطية"""
        if os.path.exists(self.db_path):
            backup_name = f"knowledge_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.db"
            backup_path = os.path.join(self.backup_dir, backup_name)
            
            import shutil
            shutil.copy2(self.db_path, backup_path)
            print(f"✅ تم إنشاء نسخة احتياطية: {backup_path}")
    
    def repair_database(self):
        """إصلاح قاعدة البيانات بشكل كامل"""
        print("🔧 بدء إصلاح قاعدة المعرفة...")
        
        # إنشاء نسخة احتياطية أولاً
        self.create_backup()
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # الجداول الأساسية المطلوبة بناءً على الأخطاء السابقة
        tables_sql = {
            'web_knowledge': '''
                CREATE TABLE IF NOT EXISTS web_knowledge (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    url TEXT UNIQUE,
                    title TEXT,
                    content TEXT,
                    summary TEXT,
                    category TEXT,
                    tags TEXT,
                    importance INTEGER DEFAULT 1,
                    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            ''',
            'debug_solutions': '''
                CREATE TABLE IF NOT EXISTS debug_solutions (
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
            ''',
            'system_patterns': '''
                CREATE TABLE IF NOT EXISTS system_patterns (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    pattern_name TEXT UNIQUE,
                    pattern_type TEXT,
                    description TEXT,
                    detection_rules TEXT,
                    solution TEXT,
                    severity TEXT DEFAULT 'medium',
                    priority INTEGER DEFAULT 5,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            ''',
            'agent_memory': '''
                CREATE TABLE IF NOT EXISTS agent_memory (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    agent_name TEXT,
                    memory_type TEXT,
                    content TEXT,
                    context TEXT,
                    importance INTEGER DEFAULT 1,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            '''
        }
        
        # إنشاء الجداول
        for table_name, create_sql in tables_sql.items():
            try:
                cursor.execute(create_sql)
                print(f"   ✅ جدول {table_name}: جاهز")
            except Exception as e:
                print(f"   ❌ خطأ في إنشاء {table_name}: {e}")
        
        # إدخال بيانات البداية
        self.seed_initial_data(cursor)
        
        conn.commit()
        
        # فحص الجداول المنشأة
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        existing_tables = [row[0] for row in cursor.fetchall()]
        print(f"📊 الجداول المتاحة: {existing_tables}")
        
        # فحص عدد السجلات
        for table in existing_tables:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"   📈 {table}: {count} سجل")
        
        conn.close()
        print("🎉 اكتمل إصلاح قاعدة المعرفة!")
    
    def seed_initial_data(self, cursor):
        """إدخال البيانات الأولية"""
        
        # حلول التصحيح الشائعة
        debug_solutions = [
            ("ModuleNotFoundError", "No module named", 
             "قم بتثبيت المكتبة المطلوبة: pip install [package_name]\nتحقق من بيئة Python virtual environment", 95),
             
            ("SyntaxError", "invalid syntax", 
             "تحقق من:\n- الأقواس المغلقة بشكل صحيح\n- النقطتين بعد الشروط والدوال\n- المسافات البادئة\n- الأخطاء المطبعية", 90),
             
            ("NameError", "is not defined", 
             "تأكد من:\n- تعريف المتغير قبل استخدامه\n- تهجئة اسم المتغير بشكل صحيح\n- استيراد المكتبات المطلوبة", 88),
             
            ("ImportError", "cannot import name", 
             "الأسباب المحتملة:\n- أخطاء في الاستيراد الدائري\n- الملف غير موجود\n- اسم غير صحيح", 85),
             
            ("FileNotFoundError", "No such file or directory", 
             "تحقق من:\n- مسار الملف\n- أذونات الملف\n- وجود الملف في المكان الصحيح", 92),
             
            ("PermissionError", "Permission denied", 
             "حلول:\n- تغيير أذونات الملف: chmod +x filename\n- التشغيل كمسؤول إذا لزم الأمر", 87)
        ]
        
        for error_type, pattern, solution, confidence in debug_solutions:
            cursor.execute('''
                INSERT OR IGNORE INTO debug_solutions 
                (error_type, error_pattern, solution, confidence) 
                VALUES (?, ?, ?, ?)
            ''', (error_type, pattern, solution, confidence))
        
        # أنماط النظام
        system_patterns = [
            ("High Memory Usage", "performance", 
             "استخدام ذاكرة مرتفع في عمليات Python", 
             '{"memory_threshold": 80, "process_pattern": "python"}',
             "تحسين الكود، استخدام المولدات، إدارة الذاكرة بشكل أفضل", "high", 1),
             
            ("Database Connection Issues", "database",
             "مشاكل في اتصال قاعدة البيانات",
             '{"error_pattern": "sqlite3.*operational.*error", "file_pattern": "*.db"}',
             "فحص مسار قاعدة البيانات، إصلاح التلف، إنشاء نسخة احتياطية", "high", 2),
             
            ("Missing Requirements", "dependency",
             "مكتبات Python مفقودة",
             '{"error_pattern": "ModuleNotFoundError|ImportError"}',
             "تثبيت المتطلبات: pip install -r requirements.txt", "medium", 3)
        ]
        
        for name, ptype, desc, rules, solution, severity, priority in system_patterns:
            cursor.execute('''
                INSERT OR IGNORE INTO system_patterns 
                (pattern_name, pattern_type, description, detection_rules, solution, severity, priority)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (name, ptype, desc, rules, solution, severity, priority))
        
        print("   🌱 تم إدخال البيانات الأولية")

if __name__ == "__main__":
    repair = KnowledgeRepair()
    repair.repair_database()
