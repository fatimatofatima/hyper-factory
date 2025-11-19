#!/usr/bin/env python3
"""
مراقبة وتقييم نظام الدروس
"""
import json
from pathlib import Path
from datetime import datetime

def monitor_lessons_system():
    print("📊 مراقبة نظام الدروس - Hyper Factory")
    print("=" * 50)
    
    # فحص الدروس
    lessons_dir = Path("ai/memory/lessons")
    lessons = list(lessons_dir.glob("*.json"))
    
    print(f"📁 عدد ملفات الدروس: {len(lessons)}")
    
    # فحص التطبيقات
    config_changes = Path("config_changes")
    applied_count = len(list(config_changes.glob("*.diff"))) if config_changes.exists() else 0
    
    print(f"🔄 عدد التغييرات المطبقة: {applied_count}")
    
    # فحص تأثير الدروس
    db_path = Path("data/knowledge/knowledge.db")
    if db_path.exists():
        import sqlite3
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM knowledge_items WHERE item_type='lesson'")
        db_lessons = cursor.fetchone()[0]
        print(f"🧠 دروس في قاعدة المعرفة: {db_lessons}")
        conn.close()
    
    # توصيات
    print("\n💡 التوصيات:")
    if applied_count == 0:
        print("  - ⚠️  لم يتم تطبيق أي درس بعد")
        print("  - 🔧 تحقق من hf_run_apply_lessons.sh")
    else:
        print(f"  - ✅ النظام يطبق الدروس ({applied_count} تغيير)")
    
    if len(lessons) > 0:
        print(f"  - 📚 يوجد {len(lessons)} درس جاهز للتطبيق")

if __name__ == "__main__":
    monitor_lessons_system()
