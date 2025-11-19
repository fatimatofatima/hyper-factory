#!/usr/bin/env python3
"""
زاحف الويب المتقدم - يجمع المعرفة من الإنترنت
"""

import requests
import sqlite3
import json
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import time
import os
from datetime import datetime

class AdvancedWebSpider:
    def __init__(self):
        self.knowledge_db = "data/knowledge/knowledge.db"
        self.setup_database()
        
    def setup_database(self):
        """إعداد قاعدة البيانات"""
        os.makedirs("data/knowledge", exist_ok=True)
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS web_knowledge (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT,
                content TEXT,
                url TEXT,
                source_type TEXT,
                category TEXT,
                difficulty TEXT,
                tags TEXT,
                crawled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        conn.commit()
        conn.close()
        
    def crawl_website(self, url, max_pages=10):
        """زحف موقع ويب"""
        print(f"🔍 يزحف {url}...")
        
        try:
            response = requests.get(url, timeout=10)
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # استخراج المعلومات
            title = soup.title.string if soup.title else "No Title"
            content = self.extract_meaningful_content(soup)
            
            # حفظ في قاعدة البيانات
            self.save_knowledge_item({
                'title': title,
                'content': content,
                'url': url,
                'source_type': 'website',
                'category': 'programming',
                'difficulty': 'intermediate',
                'tags': 'web,crawled,programming'
            })
            
            print(f"✅ تم زحف: {title}")
            
        except Exception as e:
            print(f"❌ خطأ في زحف {url}: {e}")
    
    def extract_meaningful_content(self, soup):
        """استخراج المحتوى المفيد من الصفحة"""
        # إزالة scripts وstyles
        for script in soup(["script", "style"]):
            script.decompose()
        
        # استخراج النص من العناوين والفقرات
        content_parts = []
        
        # العناوين
        for heading in soup.find_all(['h1', 'h2', 'h3']):
            content_parts.append(f"## {heading.get_text().strip()}")
        
        # الفقرات
        for paragraph in soup.find_all('p'):
            text = paragraph.get_text().strip()
            if len(text) > 50:  # تجاهل النصوص القصيرة
                content_parts.append(text)
        
        # القوائم
        for list_item in soup.find_all('li'):
            text = list_item.get_text().strip()
            if len(text) > 20:
                content_parts.append(f"- {text}")
        
        return '\n'.join(content_parts)
    
    def save_knowledge_item(self, item):
        """حفظ عنصر المعرفة في قاعدة البيانات"""
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO web_knowledge 
            (title, content, url, source_type, category, difficulty, tags)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (
            item['title'],
            item['content'],
            item['url'],
            item['source_type'],
            item['category'],
            item['difficulty'],
            item['tags']
        ))
        
        conn.commit()
        conn.close()
    
    def search_and_crawl(self, query, max_results=5):
        """البsearch والزحف بناءً على query"""
        print(f"🔎 يبحث عن: {query}")
        
        # محاكاة البحث (في الإصدار الحقيقي، نستخدم Google Custom Search API)
        search_urls = self.generate_search_urls(query, max_results)
        
        for url in search_urls:
            self.crawl_website(url)
            time.sleep(2)  # احترام سياسات الموقع
    
    def generate_search_urls(self, query, max_results):
        """إنشاء روابط بحث (محاكاة)"""
        # في الإصدار الحقيقي، نستخدم API البحث
        base_urls = [
            f"https://github.com/search?q={query.replace(' ', '+')}",
            f"https://stackoverflow.com/search?q={query.replace(' ', '+')}",
            f"https://realpython.com/search?q={query.replace(' ', '+')}",
            f"https://docs.python.org/3/search.html?q={query.replace(' ', '+')}"
        ]
        return base_urls[:max_results]
    
    def run_auto_crawl(self):
        """تشغيل الزحف التلقائي"""
        print("🚀 بدء الزحف التلقائي من الإنترنت...")
        
        # كلمات مفتاحية للبحث
        keywords = [
            "Python debugging techniques",
            "AI agents architecture", 
            "system design patterns",
            "machine learning basics",
            "web scraping Python"
        ]
        
        for keyword in keywords:
            print(f"\n📖 يبحث عن: {keyword}")
            self.search_and_crawl(keyword, max_results=3)
            time.sleep(3)

def main():
    spider = AdvancedWebSpider()
    
    print("🕷️ تشغيل Advanced Web Spider")
    print("=" * 40)
    
    # الزحف التلقائي
    spider.run_auto_crawl()
    
    # عرض الإحصائيات
    conn = sqlite3.connect(spider.knowledge_db)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM web_knowledge")
    count = cursor.fetchone()[0]
    conn.close()
    
    print(f"\n🎉 اكتمل الزحف! تم جمع {count} عنصر معرفة من الإنترنت")

if __name__ == "__main__":
    main()
