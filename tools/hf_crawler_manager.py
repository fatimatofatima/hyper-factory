#!/usr/bin/env python3
"""
مدير الزواحف - يدير جميع عمليات الزحف بشكل مركزي
"""

import sqlite3
import os
import json
from datetime import datetime

class CrawlerManager:
    def __init__(self):
        self.knowledge_db = "data/knowledge/knowledge.db"
        self.crawler_config = "config/crawler_config.json"
        self.setup_environment()
    
    def setup_environment(self):
        """إعداد البيئة"""
        os.makedirs("config", exist_ok=True)
        os.makedirs("reports/management", exist_ok=True)
        
        if not os.path.exists(self.crawler_config):
            config = {
                "max_depth": 3,
                "max_pages_per_session": 100,
                "delay_between_requests": 1,
                "allowed_domains": [
                    "docs.python.org",
                    "realpython.com", 
                    "www.w3schools.com",
                    "stackoverflow.com"
                ],
                "banned_domains": [],
                "auto_cleanup": True,
                "learning_enabled": True
            }
            
            with open(self.crawler_config, 'w') as f:
                json.dump(config, f, indent=2)
    
    def get_system_stats(self):
        """الحصول على إحصائيات النظام"""
        stats = {}
        
        try:
            conn = sqlite3.connect(self.knowledge_db)
            cursor = conn.cursor()
            
            # إحصائيات عامة
            cursor.execute('SELECT COUNT(*) FROM web_knowledge')
            stats['total_pages'] = cursor.fetchone()[0]
            
            cursor.execute('SELECT COUNT(DISTINCT url) FROM web_knowledge')
            stats['unique_urls'] = cursor.fetchone()[0]
            
            cursor.execute('SELECT COUNT(DISTINCT category) FROM web_knowledge')
            stats['categories_count'] = cursor.fetchone()[0]
            
            # أحدث الإضافات
            cursor.execute('''
                SELECT url, title, created_at 
                FROM web_knowledge 
                ORDER BY created_at DESC 
                LIMIT 5
            ''')
            stats['recent_additions'] = cursor.fetchall()
            
            # توزيع الفئات
            cursor.execute('''
                SELECT category, COUNT(*) 
                FROM web_knowledge 
                GROUP BY category 
                ORDER BY COUNT(*) DESC
            ''')
            stats['category_distribution'] = cursor.fetchall()
            
            conn.close()
            
        except Exception as e:
            stats['error'] = str(e)
        
        return stats
    
    def generate_management_report(self):
        """توليد تقرير إداري"""
        print("📊 توليد تقرير إدارة الزواحف...")
        
        stats = self.get_system_stats()
        
        report = {
            "report_date": datetime.now().isoformat(),
            "system_stats": stats,
            "recommendations": [],
            "maintenance_tasks": []
        }
        
        # تحليل وتوصيات
        if 'total_pages' in stats and stats['total_pages'] > 500:
            report["recommendations"].append("💡 فكر في تنظيف قاعدة البيانات من المحتوى القديم")
        
        if 'categories_count' in stats and stats['categories_count'] < 3:
            report["recommendations"].append("💡 جرب زحف مواقع من فئات متنوعة")
        
        # مهام الصيانة
        report["maintenance_tasks"] = [
            "تنظيف الروابط المكررة",
            "تحسين فهارس قاعدة البيانات", 
            "تحديث قائمة المجالات المسموحة",
            "مراجعة تقارير الأداء"
        ]
        
        # حفظ التقرير
        report_file = f"reports/management/crawler_management_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        # عرض التقرير
        print(f"✅ تم حفظ التقرير: {report_file}")
        print(f"📈 إجمالي الصفحات: {stats.get('total_pages', 'N/A')}")
        print(f"🌐 روابط فريدة: {stats.get('unique_urls', 'N/A')}")
        print(f"🏷️  عدد الفئات: {stats.get('categories_count', 'N/A')}")
        
        if 'recent_additions' in stats:
            print("\n📥 أحدث الإضافات:")
            for url, title, date in stats['recent_additions']:
                print(f"   - {title[:40]}...")
        
        if report["recommendations"]:
            print("\n💡 التوصيات:")
            for rec in report["recommendations"]:
                print(f"   {rec}")
    
    def run_maintenance(self):
        """تشغيل مهام الصيانة"""
        print("🔧 تشغيل مهام صيانة الزواحف...")
        
        # استيراد وإجراء الصيانة
        import subprocess
        import sys
        
        try:
            # تشغيل إصلاح الزحف
            result = subprocess.run([
                sys.executable, "scripts/fix_crawler_issues.py"
            ], capture_output=True, text=True, cwd=os.getcwd())
            
            print("✅ اكتملت مهام الصيانة")
            print(result.stdout)
            
        except Exception as e:
            print(f"❌ خطأ في الصيانة: {e}")
    
    def show_dashboard(self):
        """عرض لوحة تحكم الزواحف"""
        stats = self.get_system_stats()
        
        print("""
🚀 لوحة تحكم مدير الزواحف
==========================

📊 الإحصائيات:
   📁 الصفحات المخزنة: {pages}
   🌐 الروابط الفريدة: {urls}
   🏷️  الفئات النشطة: {categories}

⚡ الإجراءات السريعة:
   1. عرض تقرير مفصل
   2. تشغيل الصيانة
   3. تشغيل زاحف آمن
   4. فحص صحة النظام
   5. الخروج

        """.format(
            pages=stats.get('total_pages', 'N/A'),
            urls=stats.get('unique_urls', 'N/A'), 
            categories=stats.get('categories_count', 'N/A')
        ))

if __name__ == "__main__":
    manager = CrawlerManager()
    manager.show_dashboard()
    manager.generate_management_report()
    
    # عرض خيار للمستخدم
    choice = input("\nاختر الإجراء (1-5): ").strip()
    
    if choice == "1":
        manager.generate_management_report()
    elif choice == "2":
        manager.run_maintenance()
    elif choice == "3":
        print("🚀 تشغيل الزاحف الآمن...")
        import subprocess
        subprocess.run(["python3", "tools/hf_web_spider_optimized.py"])
    elif choice == "4":
        print("🔍 فحص صحة النظام...")
        import subprocess
        subprocess.run(["python3", "scripts/fix_crawler_issues.py"])
    else:
        print("👋 مع السلامة!")
