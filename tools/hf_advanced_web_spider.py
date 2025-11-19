#!/usr/bin/env python3
"""
Advanced Web Spider - زاحف ويب متقدم يجمع المعرفة من مواقع حقيقية
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

class AdvancedWebSpider:
    def __init__(self):
        self.knowledge_db = "data/knowledge/knowledge.db"
        self.visited_urls = set()
        self.setup_database()
        
    def setup_database(self):
        """إعداد قاعدة البيانات المتقدمة"""
        os.makedirs("data/knowledge", exist_ok=True)
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        # جدول المعرفة من الويب
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS web_knowledge (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT,
                content TEXT,
                url TEXT UNIQUE,
                source_type TEXT,
                category TEXT,
                difficulty TEXT,
                tags TEXT,
                content_length INTEGER,
                crawled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                quality_score REAL DEFAULT 0.0
            )
        ''')
        
        # جدول لأنماط البرمجة
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS programming_patterns (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                pattern_name TEXT,
                pattern_description TEXT,
                code_example TEXT,
                use_cases TEXT,
                category TEXT,
                difficulty TEXT,
                source_url TEXT
            )
        ''')
        
        conn.commit()
        conn.close()
        print("✅ تم إعداد قاعدة البيانات المتقدمة")
    
    def crawl_tech_websites(self):
        """زحف مواقع التقنية الشهيرة"""
        tech_sites = [
            {
                'name': 'Real Python',
                'url': 'https://realpython.com/tutorials/',
                'category': 'tutorials',
                'priority': 'high'
            },
            {
                'name': 'Python Official Docs',
                'url': 'https://docs.python.org/3/tutorial/',
                'category': 'documentation', 
                'priority': 'high'
            },
            {
                'name': 'GeeksforGeeks Python',
                'url': 'https://www.geeksforgeeks.org/python-programming-language/',
                'category': 'tutorials',
                'priority': 'medium'
            },
            {
                'name': 'W3Schools Python',
                'url': 'https://www.w3schools.com/python/',
                'category': 'tutorials',
                'priority': 'medium'
            }
        ]
        
        print("🌐 بدء زحف المواقع التقنية...")
        
        for site in tech_sites:
            print(f"🔍 يزحف {site['name']}...")
            try:
                self.crawl_site(site['url'], site['category'])
                time.sleep(2)  # احترام سياسات الموقع
            except Exception as e:
                print(f"❌ خطأ في زحف {site['name']}: {e}")
    
    def crawl_site(self, url, category):
        """زحف موقع معين"""
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (compatible; HyperFactoryBot/1.0; +http://hyper-factory.com)'
            }
            response = requests.get(url, headers=headers, timeout=15)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # استخراج المعلومات الأساسية
            title = soup.title.string if soup.title else "No Title"
            content = self.extract_meaningful_content(soup)
            
            if len(content) > 200:  # تجاهل المحتوى القصير
                self.save_web_knowledge({
                    'title': title,
                    'content': content,
                    'url': url,
                    'source_type': 'website',
                    'category': category,
                    'difficulty': self.estimate_difficulty(content),
                    'tags': self.generate_tags(content, category),
                    'content_length': len(content),
                    'quality_score': self.calculate_quality_score(content)
                })
                
                print(f"✅ تم حفظ: {title[:50]}...")
            
            # استخراج الروابط للمزيد من الزحف
            self.extract_and_crawl_links(soup, url, category)
            
        except Exception as e:
            print(f"❌ خطأ في زحف {url}: {e}")
    
    def extract_meaningful_content(self, soup):
        """استخراج المحتوى المفيد من الصفحة"""
        # إزالة العناصر غير المرغوبة
        for element in soup(["script", "style", "nav", "footer", "header"]):
            element.decompose()
        
        content_parts = []
        
        # استخراج العناوين
        for heading in soup.find_all(['h1', 'h2', 'h3']):
            text = heading.get_text().strip()
            if text and len(text) > 10:
                content_parts.append(f"## {text}")
        
        # استخراج الفقرات
        for paragraph in soup.find_all('p'):
            text = paragraph.get_text().strip()
            if len(text) > 50:  # تجاهل النصوص القصيرة
                content_parts.append(text)
        
        # استخراج كود البرمجة
        for code_block in soup.find_all(['pre', 'code']):
            code_text = code_block.get_text().strip()
            if len(code_text) > 20:
                content_parts.append(f"```python\n{code_text}\n```")
        
        # استخراج القوائم
        for list_item in soup.find_all('li'):
            text = list_item.get_text().strip()
            if len(text) > 20:
                content_parts.append(f"• {text}")
        
        return '\n\n'.join(content_parts)
    
    def extract_and_crawl_links(self, soup, base_url, category):
        """استخراج وزحف الروابط الإضافية"""
        try:
            links_found = 0
            for link in soup.find_all('a', href=True):
                href = link['href']
                full_url = urljoin(base_url, href)
                
                # تصفية الروابط
                if self.should_crawl_link(full_url) and links_found < 5:
                    if full_url not in self.visited_urls:
                        self.visited_urls.add(full_url)
                        time.sleep(1)  # تأخير بين الطلبات
                        self.crawl_site(full_url, category)
                        links_found += 1
                        
        except Exception as e:
            print(f"⚠️ خطأ في استخراج الروابط: {e}")
    
    def should_crawl_link(self, url):
        """تحديد إذا كان يجب زحف الرابط"""
        parsed = urlparse(url)
        
        # قوائم التضمين والاستبعاد
        include_keywords = ['python', 'tutorial', 'guide', 'example', 'how-to']
        exclude_keywords = ['login', 'signup', 'logout', 'admin', 'download']
        
        url_lower = url.lower()
        
        # التحقق من الكلمات المفتاحية
        has_include = any(keyword in url_lower for keyword in include_keywords)
        has_exclude = any(keyword in url_lower for keyword in exclude_keywords)
        
        return has_include and not has_exclude and parsed.netloc
    
    def estimate_difficulty(self, content):
        """تقدير صعوبة المحتوى"""
        content_lower = content.lower()
        
        advanced_terms = ['asynchronous', 'decorator', 'generator', 'metaclass', 'multithreading']
        intermediate_terms = ['function', 'class', 'module', 'import', 'exception']
        
        advanced_count = sum(1 for term in advanced_terms if term in content_lower)
        intermediate_count = sum(1 for term in intermediate_terms if term in content_lower)
        
        if advanced_count > 2:
            return 'advanced'
        elif intermediate_count > 3:
            return 'intermediate'
        else:
            return 'beginner'
    
    def generate_tags(self, content, category):
        """إنشاء وسوم للمحتوى"""
        content_lower = content.lower()
        tags = [category]
        
        # كلمات مفتاحية شائعة
        keywords = {
            'python': ['python', 'py'],
            'function': ['def ', 'function', 'lambda'],
            'class': ['class ', 'object', 'self'],
            'debug': ['debug', 'error', 'exception'],
            'web': ['flask', 'django', 'requests', 'api'],
            'data': ['pandas', 'numpy', 'dataframe', 'analysis']
        }
        
        for tag, terms in keywords.items():
            if any(term in content_lower for term in terms):
                tags.append(tag)
        
        return ','.join(tags)
    
    def calculate_quality_score(self, content):
        """حساب جودة المحتوى"""
        score = 0.0
        
        # طول المحتوى
        if len(content) > 1000:
            score += 0.3
        elif len(content) > 500:
            score += 0.2
        elif len(content) > 200:
            score += 0.1
        
        # وجود كود برمجي
        if '```' in content or 'def ' in content or 'import ' in content:
            score += 0.3
        
        # وجود أمثلة
        if 'example' in content.lower() or 'مثال' in content:
            score += 0.2
        
        # تنوع المحتوى
        lines = content.split('\n')
        if len(lines) > 10:
            score += 0.2
        
        return min(score, 1.0)
    
    def save_web_knowledge(self, item):
        """حفظ المعرفة من الويب"""
        try:
            conn = sqlite3.connect(self.knowledge_db)
            cursor = conn.cursor()
            
            cursor.execute('''
                INSERT OR REPLACE INTO web_knowledge 
                (title, content, url, source_type, category, difficulty, tags, content_length, quality_score)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                item['title'],
                item['content'],
                item['url'],
                item['source_type'],
                item['category'],
                item['difficulty'],
                item['tags'],
                item['content_length'],
                item['quality_score']
            ))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            print(f"❌ خطأ في حفظ المعرفة: {e}")
    
    def generate_knowledge_report(self):
        """توليد تقرير عن المعرفة المجموعة"""
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        # إحصائيات عامة
        cursor.execute('SELECT COUNT(*) FROM web_knowledge')
        total_items = cursor.fetchone()[0]
        
        cursor.execute('SELECT COUNT(DISTINCT category) FROM web_knowledge')
        categories_count = cursor.fetchone()[0]
        
        cursor.execute('SELECT AVG(quality_score) FROM web_knowledge')
        avg_quality = cursor.fetchone()[0] or 0
        
        cursor.execute('''
            SELECT category, COUNT(*) as count 
            FROM web_knowledge 
            GROUP BY category 
            ORDER BY count DESC
        ''')
        categories_stats = cursor.fetchall()
        
        conn.close()
        
        report = {
            'report_date': datetime.now().isoformat(),
            'total_knowledge_items': total_items,
            'categories_count': categories_count,
            'average_quality_score': f"{avg_quality:.1%}",
            'categories_breakdown': dict(categories_stats),
            'visited_urls_count': len(self.visited_urls)
        }
        
        return report

def main():
    spider = AdvancedWebSpider()
    
    print("🕷️ تشغيل Advanced Web Spider")
    print("=" * 50)
    
    # الزحف من المواقع التقنية
    spider.crawl_tech_websites()
    
    # توليد التقرير
    report = spider.generate_knowledge_report()
    
    print(f"\n📊 تقرير جمع المعرفة:")
    print(f"   📁 إجمالي العناصر: {report['total_knowledge_items']}")
    print(f"   🗂️ عدد التصنيفات: {report['categories_count']}")
    print(f"   ⭐ متوسط الجودة: {report['average_quality_score']}")
    print(f"   🌐 المواقع المزروفة: {report['visited_urls_count']}")
    
    print(f"\n📋 تفصيل التصنيفات:")
    for category, count in report['categories_breakdown'].items():
        print(f"   • {category}: {count} عنصر")
    
    print(f"\n🎉 اكتمل جمع المعرفة من الإنترنت!")

if __name__ == "__main__":
    main()
