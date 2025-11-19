#!/usr/bin/env python3
"""
الزاحف الذكي - يتعلم من الأخطاء ويتكيف تلقائياً
"""

import sqlite3
import requests
import time
import random
from datetime import datetime, timedelta
from urllib.parse import urlparse
import re
import os
import json

class SmartCrawler:
    def __init__(self):
        self.knowledge_db = "data/knowledge/knowledge.db"
        self.learning_file = "ai/memory/crawler_learning.json"
        self.setup_learning()
    
    def setup_learning(self):
        """إعداد نظام التعلم"""
        os.makedirs("ai/memory", exist_ok=True)
        
        if not os.path.exists(self.learning_file):
            learning_data = {
                "successful_domains": {},
                "failed_domains": {},
                "optimal_delays": {},
                "learned_patterns": [],
                "last_analysis": datetime.now().isoformat()
            }
            
            with open(self.learning_file, 'w') as f:
                json.dump(learning_data, f, indent=2)
    
    def learn_from_experience(self, url, success, response_time=None):
        """التعلم من تجارب الزحف"""
        try:
            with open(self.learning_file, 'r') as f:
                learning_data = json.load(f)
            
            domain = urlparse(url).netloc
            
            if success:
                # تحديث النجاحات
                if domain in learning_data["successful_domains"]:
                    learning_data["successful_domains"][domain] += 1
                else:
                    learning_data["successful_domains"][domain] = 1
                
                # تحديث أوقات الاستجابة المثلى
                if response_time:
                    if domain in learning_data["optimal_delays"]:
                        current_delay = learning_data["optimal_delays"][domain]
                        # متوسط متحرك
                        new_delay = (current_delay + response_time) / 2
                        learning_data["optimal_delays"][domain] = min(new_delay, 5.0)
                    else:
                        learning_data["optimal_delays"][domain] = response_time
            else:
                # تحديث الفشل
                if domain in learning_data["failed_domains"]:
                    learning_data["failed_domains"][domain] += 1
                else:
                    learning_data["failed_domains"][domain] = 1
            
            learning_data["last_analysis"] = datetime.now().isoformat()
            
            with open(self.learning_file, 'w') as f:
                json.dump(learning_data, f, indent=2)
                
        except Exception as e:
            print(f"⚠️  خطأ في التعلم: {e}")
    
    def get_optimal_delay(self, url):
        """الحصول على التأخير الأمثل للمجال"""
        try:
            with open(self.learning_file, 'r') as f:
                learning_data = json.load(f)
            
            domain = urlparse(url).netloc
            
            if domain in learning_data["optimal_delays"]:
                return learning_data["optimal_delays"][domain]
            else:
                # تأخير افتراضي مع بعض العشوائية
                return 1.0 + random.uniform(0, 1.0)
                
        except:
            return 1.5  # تأخير افتراضي آمن
    
    def should_crawl_domain(self, url):
        """تحديد ما إذا كان يجب زحف المجال بناءً على الخبرة"""
        try:
            with open(self.learning_file, 'r') as f:
                learning_data = json.load(f)
            
            domain = urlparse(url).netloc
            
            # إذا فشل أكثر من 5 مرات، تجنبه
            fail_count = learning_data["failed_domains"].get(domain, 0)
            if fail_count > 5:
                return False
            
            # إذا نجح كثيراً، زحفه أولاً
            success_count = learning_data["successful_domains"].get(domain, 0)
            if success_count > 3:
                return True
            
            # مجالات جديدة - جربها
            return True
            
        except:
            return True
    
    def smart_crawl(self, url):
        """زحف ذكي مع التعلم من التجارب"""
        if not self.should_crawl_domain(url):
            print(f"⏭️  تخطي المجال بناءً على الخبرة: {url}")
            return None
        
        optimal_delay = self.get_optimal_delay(url)
        time.sleep(optimal_delay)
        
        start_time = time.time()
        
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            
            response_time = time.time() - start_time
            
            # تعلم من النجاح
            self.learn_from_experience(url, True, response_time)
            
            return response
            
        except Exception as e:
            response_time = time.time() - start_time
            
            # تعلم من الفشل
            self.learn_from_experience(url, False, response_time)
            
            print(f"❌ فشل ذكي في {url}: {e}")
            return None
    
    def generate_learning_report(self):
        """توليد تقرير التعلم"""
        try:
            with open(self.learning_file, 'r') as f:
                learning_data = json.load(f)
            
            print("🧠 تقرير التعلم الآلي للزاحف:")
            print(f"   📊 المجالات الناجحة: {len(learning_data['successful_domains'])}")
            print(f"   ⚠️  المجالات الفاشلة: {len(learning_data['failed_domains'])}")
            print(f"   ⏱️  التأخيرات المثلى: {len(learning_data['optimal_delays'])}")
            
            # أفضل المجالات أداءً
            successful_domains = sorted(
                learning_data["successful_domains"].items(),
                key=lambda x: x[1],
                reverse=True
            )[:5]
            
            if successful_domains:
                print("   🏆 أفضل المجالات أداءً:")
                for domain, count in successful_domains:
                    optimal_delay = learning_data["optimal_delays"].get(domain, "N/A")
                    if optimal_delay != "N/A":
                        print(f"      - {domain}: {count} نجاح, تأخير {optimal_delay:.2f}s")
                    else:
                        print(f"      - {domain}: {count} نجاح")
            
        except Exception as e:
            print(f"❌ خطأ في تقرير التعلم: {e}")

if __name__ == "__main__":
    crawler = SmartCrawler()
    
    # اختبار الزاحف الذكي
    test_urls = [
        "https://docs.python.org/3/",
        "https://realpython.com/",
        "https://www.w3schools.com/python/"
    ]
    
    for url in test_urls:
        print(f"🔍 اختبار الزاحف الذكي: {url}")
        response = crawler.smart_crawl(url)
        
        if response:
            print(f"✅ نجاح: {len(response.content)} bytes")
        else:
            print("❌ فشل")
        
        print()
    
    crawler.generate_learning_report()
