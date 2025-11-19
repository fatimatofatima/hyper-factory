#!/usr/bin/env python3
"""
تنظيف قاعدة المعرفة - إدارة المحتوى وإزالة التكرارات
"""

import sqlite3
import os
import json
from datetime import datetime, timedelta

class KnowledgeCleaner:
    def __init__(self):
        self.knowledge_db = "data/knowledge/knowledge.db"
    
    def analyze_content(self):
        """تحليل محتوى قاعدة المعرفة"""
        print("🔍 تحليل محتوى قاعدة المعرفة...")
        
        try:
            conn = sqlite3.connect(self.knowledge_db)
            cursor = conn.cursor()
            
            # إحصائيات عامة
            cursor.execute('SELECT COUNT(*) FROM web_knowledge')
            total = cursor.fetchone()[0]
            
            cursor.execute('SELECT COUNT(DISTINCT url) FROM web_knowledge')
            unique_urls = cursor.fetchone()[0]
            
            cursor.execute('SELECT COUNT(DISTINCT category) FROM web_knowledge')
            categories = cursor.fetchone()[0]
            
            # المحتوى المكرر (بناءً على العنوان)
            cursor.execute('''
                SELECT title, COUNT(*) as count 
                FROM web_knowledge 
                GROUP BY title 
                HAVING COUNT(*) > 1
            ''')
            duplicate_titles = cursor.fetchall()
            
            # المحتوى القديم (أكثر من 30 يوم)
            cursor.execute('''
                SELECT COUNT(*) 
                FROM web_knowledge 
                WHERE created_at < datetime("now", "-30 days")
            ''')
            old_content = cursor.fetchone()[0]
            
            conn.close()
            
            report = {
                "total_records": total,
                "unique_urls": unique_urls,
                "categories_count": categories,
                "duplicate_titles": len(duplicate_titles),
                "old_content": old_content,
                "analysis_date": datetime.now().isoformat()
            }
            
            return report
            
        except Exception as e:
            print(f"❌ خطأ في التحليل: {e}")
            return {}
    
    def remove_duplicates(self):
        """إزالة المحتوى المكرر"""
        print("🧹 إزالة المحتوى المكرر...")
        
        try:
            conn = sqlite3.connect(self.knowledge_db)
            cursor = conn.cursor()
            
            # إزالة المكررات بناءً على العنوان (مع الاحتفاظ بأحدث سجل)
            cursor.execute('''
                DELETE FROM web_knowledge 
                WHERE id NOT IN (
                    SELECT MIN(id) 
                    FROM web_knowledge 
                    GROUP BY title
                )
            ''')
            
            deleted_count = cursor.rowcount
            conn.commit()
            conn.close()
            
            print(f"✅ تم حذف {deleted_count} سجل مكرر")
            return deleted_count
            
        except Exception as e:
            print(f"❌ خطأ في إزالة المكررات: {e}")
            return 0
    
    def remove_old_content(self, days=30):
        """إزالة المحتوى القديم"""
        print(f"🗑️  إزالة المحتوى الأقدم من {days} يوم...")
        
        try:
            conn = sqlite3.connect(self.knowledge_db)
            cursor = conn.cursor()
            
            cursor.execute(f'''
                DELETE FROM web_knowledge 
                WHERE created_at < datetime("now", "-{days} days")
            ''')
            
            deleted_count = cursor.rowcount
            conn.commit()
            conn.close()
            
            print(f"✅ تم حذف {deleted_count} سجل قديم")
            return deleted_count
            
        except Exception as e:
            print(f"❌ خطأ في إزالة المحتوى القديم: {e}")
            return 0
    
    def optimize_categories(self):
        """تحسين وتنظيم الفئات"""
        print("🏷️  تحسين تنظيم الفئات...")
        
        try:
            conn = sqlite3.connect(self.knowledge_db)
            cursor = conn.cursor()
            
            # تحديث الفئات بناءً على المحتوى
            cursor.execute('''
                UPDATE web_knowledge 
                SET category = CASE 
                    WHEN title LIKE '%tutorial%' OR content LIKE '%tutorial%' THEN 'tutorials'
                    WHEN title LIKE '%guide%' OR content LIKE '%guide%' THEN 'guides'
                    WHEN title LIKE '%documentation%' OR content LIKE '%documentation%' THEN 'documentation'
                    WHEN title LIKE '%news%' OR content LIKE '%news%' THEN 'news'
                    WHEN title LIKE '%discussion%' OR content LIKE '%discussion%' THEN 'discussions'
                    ELSE 'general'
                END
                WHERE category = 'tutorials'  -- تحديث الفئة الحالية فقط
            ''')
            
            updated_count = cursor.rowcount
            conn.commit()
            
            # عرض توزيع الفئات الجديد
            cursor.execute('''
                SELECT category, COUNT(*) 
                FROM web_knowledge 
                GROUP BY category 
                ORDER BY COUNT(*) DESC
            ''')
            categories = cursor.fetchall()
            
            conn.close()
            
            print(f"✅ تم تحديث {updated_count} سجل")
            print("📊 توزيع الفئات الجديد:")
            for category, count in categories:
                print(f"   - {category}: {count}")
                
        except Exception as e:
            print(f"❌ خطأ في تحسين الفئات: {e}")
    
    def generate_cleanup_report(self):
        """توليد تقرير التنظيف"""
        print("📋 توليد تقرير التنظيف...")
        
        analysis = self.analyze_content()
        
        if not analysis:
            return
        
        report = {
            "cleanup_date": datetime.now().isoformat(),
            "before_cleanup": analysis,
            "actions_taken": {},
            "after_cleanup": {}
        }
        
        # تنفيذ الإجراءات
        report["actions_taken"]["duplicates_removed"] = self.remove_duplicates()
        report["actions_taken"]["old_content_removed"] = self.remove_old_content(30)
        
        # تحسين الفئات
        self.optimize_categories()
        
        # التحليل بعد التنظيف
        report["after_cleanup"] = self.analyze_content()
        
        # حفظ التقرير
        os.makedirs("reports/diagnostics", exist_ok=True)
        report_file = f"reports/diagnostics/knowledge_cleanup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"✅ تم حفظ التقرير: {report_file}")
        
        # عرض النتائج
        print(f"\n🎯 نتائج التنظيف:")
        print(f"   📊 قبل: {analysis['total_records']} سجل")
        print(f"   📊 بعد: {report['after_cleanup']['total_records']} سجل")
        print(f"   🧹 تم حذف: {analysis['total_records'] - report['after_cleanup']['total_records']} سجل")
        print(f"   🏷️  فئات متنوعة: {report['after_cleanup']['categories_count']}")

if __name__ == "__main__":
    cleaner = KnowledgeCleaner()
    cleaner.generate_cleanup_report()
