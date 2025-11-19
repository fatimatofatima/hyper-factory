#!/usr/bin/env python3
"""
معالج المعرفة المتقدم - ينظم ويرتب المحتوى المجموع
"""

import sqlite3
import json
import re
from datetime import datetime

class KnowledgeProcessor:
    def __init__(self):
        self.knowledge_db = "data/knowledge/knowledge.db"
    
    def analyze_knowledge_base(self):
        """تحليل قاعدة المعرفة"""
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        print("🔍 يحلل قاعدة المعرفة...")
        
        # إحصائيات عامة
        cursor.execute('SELECT COUNT(*) FROM web_knowledge')
        total_items = cursor.fetchone()[0]
        
        cursor.execute('SELECT AVG(quality_score) FROM web_knowledge')
        avg_quality = cursor.fetchone()[0] or 0
        
        cursor.execute('''
            SELECT category, COUNT(*) as count, AVG(quality_score) as avg_quality
            FROM web_knowledge 
            GROUP BY category 
            ORDER BY count DESC
        ''')
        categories = cursor.fetchall()
        
        print(f"📊 إحصائيات قاعدة المعرفة:")
        print(f"   إجمالي العناصر: {total_items}")
        print(f"   متوسط الجودة: {avg_quality:.1%}")
        
        print(f"\n📋 التصنيفات:")
        for category, count, avg_qual in categories:
            print(f"   • {category}: {count} عنصر (جودة: {avg_qual:.1%})")
        
        conn.close()
        return total_items, categories
    
    def extract_programming_patterns(self):
        """استخراج أنماط البرمجة من المحتوى"""
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        cursor.execute('SELECT content FROM web_knowledge WHERE content LIKE "%def %" OR content LIKE "%class %"')
        code_contents = cursor.fetchall()
        
        patterns_found = []
        
        for content_tuple in code_contents:
            content = content_tuple[0]
            patterns = self.identify_patterns(content)
            patterns_found.extend(patterns)
        
        # حفظ الأنماط المكتشفة
        for pattern in patterns_found:
            cursor.execute('''
                INSERT OR REPLACE INTO programming_patterns 
                (pattern_name, pattern_description, code_example, use_cases, category, difficulty, source_url)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                pattern['name'],
                pattern['description'],
                pattern['code_example'],
                pattern['use_cases'],
                pattern['category'],
                pattern['difficulty'],
                pattern.get('source_url', '')
            ))
        
        conn.commit()
        conn.close()
        
        print(f"✅ تم استخراج {len(patterns_found)} نمط برمجة")
        return patterns_found
    
    def identify_patterns(self, content):
        """تحديد أنماط البرمجة في المحتوى"""
        patterns = []
        
        # نمط الدالة
        function_matches = re.findall(r'def\s+(\w+)\s*\([^)]*\):\s*(.*?)(?=\n\s*\n|\Z)', content, re.DOTALL)
        for func_name, func_body in function_matches:
            if len(func_body.strip()) > 10:
                patterns.append({
                    'name': f'function_{func_name}',
                    'description': f'دالة {func_name} - {self.estimate_function_purpose(func_body)}',
                    'code_example': f"def {func_name}(...):\n{func_body[:200]}",
                    'use_cases': 'معالجة البيانات، تنفيذ العمليات',
                    'category': 'functions',
                    'difficulty': 'beginner'
                })
        
        # نمط الشرط
        if_matches = re.findall(r'if\s+[^:]+:(.*?)(?=elif|else|\n\s*\n)', content, re.DOTALL)
        if len(if_matches) > 2:
            patterns.append({
                'name': 'conditional_logic',
                'description': 'منطق شرطي متعدد الشروط',
                'code_example': if_matches[0][:150],
                'use_cases': 'اتخاذ القرارات، التحقق من الشروط',
                'category': 'control_flow',
                'difficulty': 'beginner'
            })
        
        # نمط الحلقات
        loop_matches = re.findall(r'(for\s+\w+\s+in\s+[^:]+:|while\s+[^:]+:)(.*?)(?=\n\s*\n)', content, re.DOTALL)
        if loop_matches:
            patterns.append({
                'name': 'loop_pattern',
                'description': 'نمط الحلقات التكرارية',
                'code_example': loop_matches[0][0] + loop_matches[0][1][:100],
                'use_cases': 'معالجة المجموعات، التكرار',
                'category': 'loops',
                'difficulty': 'beginner'
            })
        
        return patterns
    
    def estimate_function_purpose(self, function_body):
        """تقدير هدف الدالة من محتواها"""
        body_lower = function_body.lower()
        
        if any(word in body_lower for word in ['calculate', 'sum', 'total', 'average']):
            return 'عمليات حسابية'
        elif any(word in body_lower for word in ['read', 'write', 'file', 'open']):
            return 'معالجة الملفات'
        elif any(word in body_lower for word in ['request', 'get', 'post', 'api']):
            return 'اتصالات الشبكة'
        elif any(word in body_lower for word in ['validate', 'check', 'verify']):
            return 'التحقق من الصحة'
        else:
            return 'معالجة عامة'
    
    def generate_knowledge_index(self):
        """إنشاء فهرس للمعرفة للبحث السريع"""
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        # إنشاء جدول الفهرس إذا لم يكن موجوداً
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS knowledge_index (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                keyword TEXT,
                item_ids TEXT,
                category TEXT,
                relevance_score REAL
            )
        ''')
        
        # استخراج الكلمات المفتاحية من المحتوى
        cursor.execute('SELECT id, content, category FROM web_knowledge')
        items = cursor.fetchall()
        
        keyword_index = {}
        
        for item_id, content, category in items:
            keywords = self.extract_keywords(content)
            
            for keyword, score in keywords.items():
                if keyword not in keyword_index:
                    keyword_index[keyword] = []
                keyword_index[keyword].append((item_id, score))
        
        # حفظ الفهرس
        for keyword, items_list in keyword_index.items():
            item_ids = ','.join(str(item[0]) for item in items_list)
            avg_score = sum(item[1] for item in items_list) / len(items_list)
            
            cursor.execute('''
                INSERT OR REPLACE INTO knowledge_index 
                (keyword, item_ids, category, relevance_score)
                VALUES (?, ?, ?, ?)
            ''', (keyword, item_ids, category, avg_score))
        
        conn.commit()
        conn.close()
        
        print(f"✅ تم إنشاء فهرس بـ {len(keyword_index)} كلمة مفتاحية")
        return len(keyword_index)
    
    def extract_keywords(self, content):
        """استخراج الكلمات المفتاحية من المحتوى"""
        # إزالة علامات الترقيم وتحويل للنص الصغير
        words = re.findall(r'\b[a-zA-Z]{4,}\b', content.lower())
        
        # كلمات شائعة في البرمجة (للاستبعاد)
        common_words = {'this', 'that', 'with', 'from', 'have', 'were', 'them', 'will', 'then', 'when'}
        programming_terms = {'function', 'class', 'method', 'object', 'variable', 'value', 'return'}
        
        word_freq = {}
        for word in words:
            if word not in common_words and word in programming_terms:
                word_freq[word] = word_freq.get(word, 0) + 1
        
        # حساب درجات الأهمية
        max_freq = max(word_freq.values()) if word_freq else 1
        keyword_scores = {word: freq/max_freq for word, freq in word_freq.items()}
        
        return keyword_scores
    
    def create_knowledge_summary(self):
        """إنشاء ملخص للمعرفة المجموعة"""
        total_items, categories = self.analyze_knowledge_base()
        patterns_count = len(self.extract_programming_patterns())
        index_size = self.generate_knowledge_index()
        
        summary = {
            'summary_date': datetime.now().isoformat(),
            'total_knowledge_items': total_items,
            'programming_patterns': patterns_count,
            'search_index_size': index_size,
            'categories_available': len(categories),
            'status': 'knowledge_base_ready'
        }
        
        # حفظ الملخص
        with open('ai/memory/knowledge_summary.json', 'w') as f:
            json.dump(summary, f, indent=2)
        
        print(f"\n📚 ملخص قاعدة المعرفة:")
        for key, value in summary.items():
            print(f"   {key}: {value}")
        
        return summary

def main():
    processor = KnowledgeProcessor()
    
    print("🧠 معالج المعرفة المتقدم")
    print("=" * 40)
    
    # معالجة المعرفة المجموعة
    summary = processor.create_knowledge_summary()
    
    print(f"\n🎉 اكتملت معالجة المعرفة!")
    print(f"   قاعدة المعرفة جاهزة للاستخدام")

if __name__ == "__main__":
    main()
