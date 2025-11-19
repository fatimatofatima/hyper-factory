#!/usr/bin/env python3
"""
Web Spider المحسن - مع حدود للتعمق وتجنب التكرار
"""

import requests
import sqlite3
import json
import os
import time
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import re
from datetime import datetime
import sys

class OptimizedWebSpider:
    def __init__(self, max_depth=3, max_pages=100, delay=1):
        self.knowledge_db = "data/knowledge/knowledge.db"
        self.visited_urls = set()
        self.urls_to_visit = []
        self.max_depth = max_depth
        self.max_pages = max_pages
        self.delay = delay
        self.crawled_count = 0
        self.setup_database()
        
        # زيادة عمق العودية للنظام
        sys.setrecursionlimit(10000)
    
    def setup_database(self):
        """إعداد قاعدة البيانات بشكل آمن"""
        os.makedirs("data/knowledge", exist_ok=True)
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        # إنشاء الجداول إذا لم تكن موجودة
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS web_knowledge (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                url TEXT UNIQUE,
                title TEXT,
                content TEXT,
                summary TEXT,
                category TEXT,
                tags TEXT,
                importance INTEGER DEFAULT 1,
                depth INTEGER DEFAULT 0,
                last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        conn.commit()
        conn.close()
        print("✅ تم إعداد قاعدة البيانات")
    
    def is_valid_url(self, url):
        """التحقق من صحة الرابط"""
        try:
            parsed = urlparse(url)
            return bool(parsed.netloc) and bool(parsed.scheme)
        except Exception:
            return False
    
    def should_crawl(self, url, depth):
        """تحديد ما إذا كان يجب زحف الرابط"""
        if depth > self.max_depth:
            return False
        
        if self.crawled_count >= self.max_pages:
            return False
        
        if url in self.visited_urls:
            return False
        
        # تجنب أنواع الملفات غير المرغوبة
        excluded_extensions = ['.pdf', '.doc', '.docx', '.zip', '.tar', '.gz']
        if any(url.lower().endswith(ext) for ext in excluded_extensions):
            return False
        
        return True
    
    def extract_content(self, soup):
        """استخراج المحتوى من الصفحة"""
        # إزالة العلامات غير المرغوبة
        for script in soup(["script", "style", "nav", "footer", "header"]):
            script.decompose()
        
        # استخراج النص
        text = soup.get_text()
        
        # تنظيف النص
        lines = (line.strip() for line in text.splitlines())
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        text = ' '.join(chunk for chunk in chunks if chunk)
        
        return text
    
    def generate_summary(self, content, max_length=200):
        """توليد ملخص للمحتوى"""
        if len(content) <= max_length:
            return content
        
        # البحث عن نقطة توقف منطقية
        sentences = re.split(r'[.!?]+', content)
        summary = ""
        
        for sentence in sentences:
            if len(summary + sentence) < max_length:
                summary += sentence + ". "
            else:
                break
        
        return summary.strip() or content[:max_length] + "..."
    
    def categorize_content(self, title, content, url):
        """تصنيف المحتوى تلقائياً"""
        categories = {
            'python': r'python|numpy|pandas|django|flask',
            'programming': r'programming|code|algorithm|software|developer',
            'tutorial': r'tutorial|guide|how to|example|step by step',
            'documentation': r'documentation|api|reference|manual',
            'discussion': r'discussion|forum|mailing list|thread',
            'news': r'news|release|update|announcement'
        }
        
        text = (title + " " + content).lower()
        
        for category, pattern in categories.items():
            if re.search(pattern, text, re.IGNORECASE):
                return category
        
        return 'general'
    
    def extract_tags(self, title, content):
        """استخراج الوسوم من المحتوى"""
        words = re.findall(r'\b[a-zA-Z]{4,}\b', title + " " + content)
        common_words = {'this', 'that', 'with', 'from', 'have', 'been', 'will', 'your', 'more', 'when'}
        
        tags = [word.lower() for word in words[:10] 
                if word.lower() not in common_words and len(word) > 3]
        
        return list(set(tags))[:5]
    
    def save_to_database(self, url, title, content, depth):
        """حفظ البيانات في قاعدة المعرفة"""
        try:
            summary = self.generate_summary(content)
            category = self.categorize_content(title, content, url)
            tags = ",".join(self.extract_tags(title, content))
            
            conn = sqlite3.connect(self.knowledge_db)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT OR REPLACE INTO web_knowledge 
                (url, title, content, summary, category, tags, depth)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (url, title, content, summary, category, tags, depth))
            
            conn.commit()
            conn.close()
            
            return True
            
        except Exception as e:
            print(f"❌ خطأ في حفظ {url}: {e}")
            return False
    
    def crawl_page(self, url, depth=0):
        """زحف صفحة فردية"""
        if not self.should_crawl(url, depth):
            return []
        
        print(f"🔍 يزحف [{depth}]: {url}")
        
        try:
            # تأخير بين الطلبات
            time.sleep(self.delay)
            
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
            
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # استخراج العنوان والمحتوى
            title = soup.title.string if soup.title else "No Title"
            content = self.extract_content(soup)
            
            # حفظ في قاعدة البيانات
            if self.save_to_database(url, title, content, depth):
                print(f"✅ تم حفظ: {title[:50]}...")
                self.crawled_count += 1
            
            self.visited_urls.add(url)
            
            # استخراج الروابط للمستوى التالي
            if depth < self.max_depth:
                links = []
                for link in soup.find_all('a', href=True):
                    href = link['href']
                    full_url = urljoin(url, href)
                    
                    if self.is_valid_url(full_url) and full_url not in self.visited_urls:
                        links.append(full_url)
                
                return links
            
            return []
            
        except requests.RequestException as e:
            print(f"❌ خطأ في زحف {url}: {e}")
            return []
        except Exception as e:
            print(f"❌ خطأ غير متوقع في {url}: {e}")
            return []
    
    def crawl_site(self, start_urls):
        """بدء الزحف من روابط البداية"""
        print("🚀 بدء الزحف المحسن...")
        print(f"📊 الإعدادات: عمق {self.max_depth}, حد {self.max_pages} صفحة")
        
        self.urls_to_visit = [(url, 0) for url in start_urls]
        
        while self.urls_to_visit and self.crawled_count < self.max_pages:
            url, depth = self.urls_to_visit.pop(0)
            
            if url not in self.visited_urls:
                new_links = self.crawl_page(url, depth)
                
                # إضافة الروابط الجديدة للمستوى التالي
                if depth < self.max_depth:
                    for link in new_links:
                        if link not in [u for u, d in self.urls_to_visit]:
                            self.urls_to_visit.append((link, depth + 1))
        
        self.generate_report()
    
    def generate_report(self):
        """توليد تقرير عن الزحف"""
        try:
            conn = sqlite3.connect(self.knowledge_db)
            cursor = conn.cursor()
            
            cursor.execute('SELECT COUNT(*) FROM web_knowledge')
            total_records = cursor.fetchone()[0]
            
            cursor.execute('SELECT COUNT(DISTINCT category) FROM web_knowledge')
            categories_count = cursor.fetchone()[0]
            
            cursor.execute('''
                SELECT category, COUNT(*) 
                FROM web_knowledge 
                GROUP BY category 
                ORDER BY COUNT(*) DESC
            ''')
            categories = cursor.fetchall()
            
            conn.close()
            
            report = {
                "timestamp": datetime.now().isoformat(),
                "total_crawled": self.crawled_count,
                "total_in_database": total_records,
                "unique_categories": categories_count,
                "categories_breakdown": dict(categories),
                "max_depth": self.max_depth,
                "max_pages": self.max_pages
            }
            
            # حفظ التقرير
            os.makedirs("reports/diagnostics", exist_ok=True)
            report_file = f"reports/diagnostics/web_spider_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            
            with open(report_file, 'w') as f:
                json.dump(report, f, indent=2)
            
            print("\n📊 تقرير الزحف:")
            print(f"   ✅ الصفحات المزحوفة: {self.crawled_count}")
            print(f"   📁 السجلات في قاعدة البيانات: {total_records}")
            print(f"   🏷️  الفئات: {categories_count}")
            print(f"   📄 التقرير الكامل: {report_file}")
            
        except Exception as e:
            print(f"⚠️  خطأ في إنشاء التقرير: {e}")
    
    def safe_crawl(self, start_urls):
        """زحف آمن مع معالجة الأخطاء"""
        try:
            self.crawl_site(start_urls)
            print("🎉 اكتمل الزحف الآمن!")
        except KeyboardInterrupt:
            print("\n⏹️  تم إيقاف الزحف بواسطة المستخدم")
            self.generate_report()
        except Exception as e:
            print(f"❌ خطأ جسيم في الزحف: {e}")
            self.generate_report()

# مثال على الاستخدام
if __name__ == "__main__":
    # روابط بداية آمنة ومحدودة
    safe_start_urls = [
        "https://docs.python.org/3/tutorial/",
        "https://realpython.com/python-basics/",
        "https://www.w3schools.com/python/"
    ]
    
    spider = OptimizedWebSpider(
        max_depth=2,      # عمق محدود
        max_pages=50,     # عدد صفحات محدود
        delay=1          # تأخير 1 ثانية بين الطلبات
    )
    
    spider.safe_crawl(safe_start_urls)
