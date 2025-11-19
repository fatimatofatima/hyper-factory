#!/usr/bin/env python3
"""
فحص أداء النظام الحالي وقدراته
"""

import time
import sqlite3
import subprocess
from pathlib import Path

def check_knowledge_db_performance():
    """فحص أداء قاعدة المعرفة"""
    print("🧠 فحص أداء قاعدة المعرفة...")
    
    db_path = Path("data/knowledge/knowledge.db")
    if not db_path.exists():
        print("❌ قاعدة المعرفة غير موجودة")
        return
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        start_time = time.time()
        
        # فحص الجداول
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        
        # فحص حجم البيانات
        stats = {}
        for table in tables:
            table_name = table[0]
            cursor.execute(f"SELECT COUNT(*) FROM {table_name};")
            count = cursor.fetchone()[0]
            stats[table_name] = count
        
        query_time = time.time() - start_time
        
        print(f"✅ عدد الجداول: {len(tables)}")
        print(f"📊 إحصائيات الجداول: {stats}")
        print(f"⏱️ وقت الاستعلام: {query_time:.3f} ثانية")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ خطأ في فحص قاعدة البيانات: {e}")

def check_worker_performance():
    """فحص أداء العمال الحاليين"""
    print("\n👷 فحص أداء العمال...")
    
    worker_patterns = ["ingestor", "processor", "analyzer", "reporter"]
    workers_found = []
    
    for pattern in worker_patterns:
        worker_files = list(Path(".").glob(f"**/*{pattern}*.py"))
        if worker_files:
            workers_found.append(pattern)
    
    print(f"✅ العمال النشطين: {workers_found}")
    print(f"📋 إجمالي العمال: {len(workers_found)}/4")
    
    # فحص إذا كان النظام يعمل
    try:
        result = subprocess.run(["pgrep", "-f", "python.*worker"], 
                              capture_output=True, text=True)
        if result.stdout:
            print("🟢 النظام يعمل (عمال نشطين)")
        else:
            print("🟡 النظام متوقف (لا توجد عمليات نشطة)")
    except:
        print("🔴 لا يمكن فحص حالة النظام")

def check_system_health():
    """فحص صحة النظام العام"""
    print("\n🏥 فحص صحة النظام...")
    
    # فحص المساحات
    try:
        disk_usage = subprocess.run(["df", "-h", "."], capture_output=True, text=True)
        print(f"💾 استخدام القرص:\n{disk_usage.stdout.splitlines()[1]}")
    except:
        print("❌ لا يمكن فحص استخدام القرص")
    
    # فحص الذاكرة
    try:
        memory = subprocess.run(["free", "-h"], capture_output=True, text=True)
        print(f"🧠 استخدام الذاكرة:\n{memory.stdout.splitlines()[1]}")
    except:
        print("❌ لا يمكن فحص الذاكرة")

def main():
    print("🔧 فحص أداء النظام الحالي")
    print("=" * 40)
    
    check_knowledge_db_performance()
    check_worker_performance() 
    check_system_health()
    
    print("\n" + "=" * 40)
    print("✅ اكتمل فحص الأداء")

if __name__ == "__main__":
    main()
