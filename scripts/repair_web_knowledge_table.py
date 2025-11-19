#!/usr/bin/env python3
"""
إصلاح هيكل جدول web_knowledge - إضافة الأعمدة المفقودة
"""

import sqlite3
import os
from datetime import datetime

def repair_web_knowledge_table():
    db_path = 'data/knowledge/knowledge.db'
    
    if not os.path.exists(db_path):
        print("❌ قاعدة المعرفة غير موجودة")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("🔧 إصلاح هيكل جدول web_knowledge...")
    
    # فحص الأعمدة الحالية
    cursor.execute("PRAGMA table_info(web_knowledge)")
    columns = [col[1] for col in cursor.fetchall()]
    print(f"📊 الأعمدة الحالية: {columns}")
    
    # الأعمدة المطلوبة
    required_columns = ['created_at', 'last_updated', 'depth', 'importance', 'tags', 'summary']
    missing_columns = [col for col in required_columns if col not in columns]
    
    if missing_columns:
        print(f"⚠️  الأعمدة المفقودة: {missing_columns}")
        
        # إضافة الأعمدة المفقودة
        for column in missing_columns:
            try:
                if column in ['created_at', 'last_updated']:
                    cursor.execute(f'ALTER TABLE web_knowledge ADD COLUMN {column} DATETIME DEFAULT CURRENT_TIMESTAMP')
                elif column == 'depth':
                    cursor.execute(f'ALTER TABLE web_knowledge ADD COLUMN {column} INTEGER DEFAULT 0')
                elif column == 'importance':
                    cursor.execute(f'ALTER TABLE web_knowledge ADD COLUMN {column} INTEGER DEFAULT 1')
                else:
                    cursor.execute(f'ALTER TABLE web_knowledge ADD COLUMN {column} TEXT')
                
                print(f"✅ تم إضافة العمود: {column}")
            except Exception as e:
                print(f"⚠️  خطأ في إضافة {column}: {e}")
        
        # تحديث البيانات القديمة
        try:
            cursor.execute("UPDATE web_knowledge SET created_at = CURRENT_TIMESTAMP WHERE created_at IS NULL")
            cursor.execute("UPDATE web_knowledge SET last_updated = CURRENT_TIMESTAMP WHERE last_updated IS NULL")
            cursor.execute("UPDATE web_knowledge SET depth = 0 WHERE depth IS NULL")
            cursor.execute("UPDATE web_knowledge SET importance = 1 WHERE importance IS NULL")
            print("✅ تم تحديث البيانات القديمة")
        except Exception as e:
            print(f"⚠️  خطأ في تحديث البيانات: {e}")
    
    else:
        print("✅ هيكل الجدول صحيح")
    
    conn.commit()
    
    # فحص نهائي
    cursor.execute("PRAGMA table_info(web_knowledge)")
    final_columns = [col[1] for col in cursor.fetchall()]
    print(f"📊 الأعمدة النهائية: {len(final_columns)} عمود")
    
    conn.close()

def optimize_database():
    """تحسين قاعدة البيانات"""
    print("⚡ تحسين قاعدة البيانات...")
    
    try:
        conn = sqlite3.connect('data/knowledge/knowledge.db')
        cursor = conn.cursor()
        
        # إنشاء الفهارس
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_web_url ON web_knowledge(url)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_web_category ON web_knowledge(category)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_web_created ON web_knowledge(created_at)')
        
        # تحسين المساحة
        cursor.execute('VACUUM')
        
        conn.commit()
        conn.close()
        print("✅ تم تحسين قاعدة البيانات")
        
    except Exception as e:
        print(f"❌ خطأ في التحسين: {e}")

if __name__ == "__main__":
    repair_web_knowledge_table()
    optimize_database()
