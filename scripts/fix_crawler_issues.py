#!/usr/bin/env python3
"""
إصلاح مشاكل الزحف - الإصدار المصحح للمسارات
"""

import sqlite3
import os
import requests
import json
from datetime import datetime

class CrawlerFix:
    def __init__(self):
        self.knowledge_db = "data/knowledge/knowledge.db"
    
    def analyze_crawler_issues(self):
        """تحليل مشاكل الزحف الحالية"""
        print("🔍 تحليل مشاكل الزحف...")
        
        issues = []
        
        # فحص قاعدة البيانات
        try:
            conn = sqlite3.connect(self.knowledge_db)
            cursor = conn.cursor()
            
            # فحص جدول web_knowledge
            cursor.execute('SELECT COUNT(*) FROM web_knowledge')
            total_records = cursor.fetchone()[0]
            
            cursor.execute('SELECT COUNT(DISTINCT url) FROM web_knowledge')
            unique_urls = cursor.fetchone()[0]
            
            cursor.execute('SELECT COUNT(DISTINCT category) FROM web_knowledge')
            categories_count = cursor.fetchone()[0]
            
            conn.close()
            
            print(f"📊 إحصائيات قاعدة المعرفة:")
            print(f"   📁 إجمالي السجلات: {total_records}")
            print(f"   🌐 روابط فريدة: {unique_urls}")
            print(f"   🏷️  عدد الفئات: {categories_count}")
            
            if total_records > 1000:
                issues.append("⚠️  قاعدة المعرفة كبيرة - قد تحتاج تنظيف")
            
        except Exception as e:
            issues.append(f"❌ خطأ في فحص قاعدة البيانات: {e}")
        
        # فحص اتصال الإنترنت
        try:
            response = requests.get("https://www.google.com", timeout=5)
            print("✅ اتصال الإنترنت: نشط")
        except:
            issues.append("❌ مشكلة في اتصال الإنترنت")
        
        return issues
    
    def generate_health_report(self):
        """توليد تقرير صحة الزحف"""
        print("📋 توليد تقرير الصحة...")
        
        issues = self.analyze_crawler_issues()
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "issues_found": len(issues),
            "issues": issues,
            "recommendations": [
                "استخدم OptimizedWebSpider للزحف الآمن",
                "حدد max_depth إلى 2 أو 3",
                "استخدم delay=1 بين الطلبات",
                "راقب حجم قاعدة البيانات بانتظام"
            ]
        }
        
        # حفظ التقرير
        os.makedirs("reports/diagnostics", exist_ok=True)
        report_file = "reports/diagnostics/crawler_health_report.json"
        
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"✅ تم حفظ التقرير: {report_file}")
        
        # عرض النتائج
        print("\n🎯 نتائج التحليل:")
        if issues:
            for issue in issues:
                print(f"   {issue}")
        else:
            print("   ✅ لا توجد مشاكل حرجة")

if __name__ == "__main__":
    fixer = CrawlerFix()
    fixer.generate_health_report()
