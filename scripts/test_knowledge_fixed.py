#!/usr/bin/env python3
"""
اختبار قاعدة المعرفة بدون أخطاء بناء الجملة
"""

import sqlite3
import os
import json

def test_knowledge_base():
    db_path = 'data/knowledge/knowledge.db'
    
    print("🧪 اختبار قاعدة المعرفة...")
    print("=" * 40)
    
    if not os.path.exists(db_path):
        print("❌ قاعدة المعرفة غير موجودة")
        return
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # فحص الجداول
        cursor.execute('SELECT name FROM sqlite_master WHERE type="table"')
        tables = [table[0] for table in cursor.fetchall()]
        print('✅ الجداول الموجودة:', tables)
        
        # فحص عدد السجلات
        print("\\n📊 عدد السجلات في كل جدول:")
        for table in tables:
            cursor.execute(f'SELECT COUNT(*) FROM {table}')
            count = cursor.fetchone()[0]
            print(f'   📈 {table}: {count} سجل')
        
        # فحص محتوى جدول debug_solutions
        print("\\n🔍 محتوى جدول debug_solutions:")
        cursor.execute('SELECT error_type, error_pattern, solution, confidence FROM debug_solutions')
        solutions = cursor.fetchall()
        
        for i, (error_type, pattern, solution, confidence) in enumerate(solutions, 1):
            print(f"   {i}. {error_type}: {pattern} (ثقة: {confidence}%)")
            print(f"      💡 {solution}")
        
        conn.close()
        print('\\n✅ قاعدة المعرفة سليمة ومكتملة')
        
    except Exception as e:
        print(f'❌ خطأ في قاعدة المعرفة: {e}')

def test_memory_files():
    """اختبار ملفات الذاكرة"""
    print("\\n🧠 اختبار ملفات الذاكرة:")
    print("=" * 40)
    
    memory_files = [
        'ai/memory/debug_cases.json',
        'ai/memory/debug_expert_performance.json',
        'ai/memory/quality_status.json'
    ]
    
    for file_path in memory_files:
        if os.path.exists(file_path):
            try:
                with open(file_path, 'r') as f:
                    data = json.load(f)
                
                if isinstance(data, list):
                    status = f"{len(data)} عنصر"
                else:
                    status = "موجود"
                
                print(f"✅ {file_path}: {status}")
            except Exception as e:
                print(f"❌ {file_path}: خطأ في القراءة - {e}")
        else:
            print(f"⚠️  {file_path}: غير موجود")

def test_storage():
    """اختبار المساحات التخزينية"""
    print("\\n💾 اختبار المساحات التخزينية:")
    print("=" * 40)
    
    try:
        import shutil
        total, used, free = shutil.disk_usage(".")
        print(f"   💿 المساحة الإجمالية: {total // (2**30)} GB")
        print(f"   💿 المساحة المستخدمة: {used // (2**30)} GB") 
        print(f"   💿 المساحة الحرة: {free // (2**30)} GB")
    except Exception as e:
        print(f"   ❌ خطأ في فحص المساحة: {e}")

if __name__ == "__main__":
    test_knowledge_base()
    test_memory_files()
    test_storage()
