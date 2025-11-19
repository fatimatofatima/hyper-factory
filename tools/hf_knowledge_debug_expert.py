#!/usr/bin/env python3
"""
Knowledge-Enhanced Debug Expert - خبير تصحيح مدعوم بالمعرفة من الإنترنت
"""

import sqlite3
import json
import re
from datetime import datetime
from tools.hf_knowledge_search import KnowledgeSearch

class KnowledgeDebugExpert:
    def __init__(self):
        self.knowledge_db = "data/knowledge/knowledge.db"
        self.search_engine = KnowledgeSearch()
        self.setup_enhanced_knowledge()
    
    def setup_enhanced_knowledge(self):
        """إعداد المعرفة المحسنة للتصحيح"""
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        # إنشاء جدول حلول الأخطاء المتراكمة
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS debug_solutions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                error_pattern TEXT UNIQUE,
                solution TEXT,
                category TEXT,
                confidence_score REAL DEFAULT 0.0,
                usage_count INTEGER DEFAULT 0,
                success_rate REAL DEFAULT 0.0,
                last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # إضافة حلول أولية من المعرفة المجموعة
        initial_solutions = [
            ('ModuleNotFoundError.*No module named', 
             'قم بتثبيت المكتبة: pip install <package_name>', 
             'import_issues', 0.95),
             
            ('SyntaxError.*invalid syntax', 
             'تحقق من: 1) الأقواس المغلقة 2) النقطتين بعد الشروط 3) المسافات البادئة 4) الأخطاء المطبعية', 
             'syntax_basics', 0.90),
             
            ('NameError.*is not defined', 
             'تأكد من: 1) تعريف المتغير قبل استخدامه 2) تهجئة الاسم بشكل صحيح 3) نطاق المتغير', 
             'variable_scope', 0.88),
             
            ('IndentationError', 
             'تحقق من تسوية المسافات البادئة. استخدم المسافات أو Tabs بشكل متسق في كل الملف', 
             'syntax_basics', 0.92),
             
            ('TypeError.*concatenate', 
             'تحويل الأنواع قبل الدمج: str(int_value) أو استخدام f-strings: f"{text} {number}"', 
             'type_conversion', 0.85),
             
            ('FileNotFoundError.*No such file or directory', 
             'تأكد من: 1) وجود الملف في المسار 2) صحة اسم الملف 3) أذونات القراءة', 
             'file_operations', 0.89),
             
            ('IndexError.*list index out of range', 
             'تأكد من أن الفهرس ضمن نطاق القائمة. استخدم len(list) للتحقق من الطول', 
             'list_operations', 0.87),
             
            ('KeyError', 
             'المفتاح غير موجود في القاموس. استخدم dict.get(key) أو تحقق من وجود المفتاح أولاً', 
             'dictionary_ops', 0.84),
             
            ('AttributeError.*object has no attribute', 
             'تحقق من: 1) اسم السمة بشكل صحيح 2) أن الكائن يدعم هذه السمة 3) استيراد المكتبات اللازمة', 
             'object_orientation', 0.83),
             
            ('ValueError', 
             'القيمة غير مناسبة للعملية. تحقق من تنسيق البيانات ونطاق القيم المقبول', 
             'data_validation', 0.80)
        ]
        
        for pattern, solution, category, confidence in initial_solutions:
            cursor.execute('''
                INSERT OR IGNORE INTO debug_solutions 
                (error_pattern, solution, category, confidence_score)
                VALUES (?, ?, ?, ?)
            ''', (pattern, solution, category, confidence))
        
        conn.commit()
        conn.close()
        print("✅ تم إعداد المعرفة المحسنة للتصحيح")
    
    def analyze_error_with_knowledge(self, error_message, code_snippet="", context=""):
        """تحليل الخطأ باستخدام المعرفة الموسعة"""
        print(f"🔍 يحلل الخطأ باستخدام المعرفة: {error_message}")
        
        # البحث في حلول الأخطاء المتراكمة
        db_solution = self.search_debug_solutions(error_message)
        if db_solution and db_solution['confidence'] > 0.8:
            return db_solution
        
        # البحث في المعرفة العامة من الويب
        web_solution = self.search_web_knowledge(error_message, code_snippet)
        if web_solution:
            return web_solution
        
        # التحليل الذكي باستخدام الأنماط
        pattern_solution = self.analyze_with_patterns(error_message, code_snippet)
        if pattern_solution:
            return pattern_solution
        
        # الحل العام المدعوم بالمعرفة
        return self.generate_knowledge_backed_solution(error_message, context)
    
    def search_debug_solutions(self, error_message):
        """البحث في حلول الأخطاء المتراكمة"""
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT error_pattern, solution, category, confidence_score 
            FROM debug_solutions 
            ORDER BY confidence_score DESC, usage_count DESC
        ''')
        
        solutions = cursor.fetchall()
        
        for pattern, solution, category, confidence in solutions:
            if re.search(pattern, error_message, re.IGNORECASE):
                # تحديث الإحصائيات
                cursor.execute('''
                    UPDATE debug_solutions 
                    SET usage_count = usage_count + 1,
                        last_used = CURRENT_TIMESTAMP
                    WHERE error_pattern = ?
                ''', (pattern,))
                conn.commit()
                
                conn.close()
                return {
                    'solution': solution,
                    'confidence': confidence,
                    'source': 'debug_knowledge_base',
                    'category': category,
                    'pattern_matched': pattern
                }
        
        conn.close()
        return None
    
    def search_web_knowledge(self, error_message, code_snippet=""):
        """البحث في المعرفة المجموعة من الويب"""
        # استخراج الكلمات المفتاحية من الخطأ
        keywords = self.extract_keywords_from_error(error_message)
        
        best_solution = None
        best_score = 0
        
        for keyword in keywords[:3]:  # البحث بأهم 3 كلمات مفتاحية
            results = self.search_engine.search(keyword, category='programming', limit=5)
            
            for result in results:
                relevance_score = self.calculate_solution_relevance(result['content'], error_message, code_snippet)
                
                if relevance_score > best_score:
                    best_score = relevance_score
                    best_solution = {
                        'solution': self.extract_solution_from_content(result['content'], error_message),
                        'confidence': min(relevance_score / 10, 0.9),  # تطبيع بين 0-0.9
                        'source': 'web_knowledge',
                        'source_url': result['url'],
                        'relevance_score': relevance_score
                    }
        
        return best_solution if best_score > 5 else None
    
    def extract_keywords_from_error(self, error_message):
        """استخراج الكلمات المفتاحية من رسالة الخطأ"""
        # إزالة الأجزاء الشائعة غير المهمة
        cleaned_error = re.sub(r'File ".*?"', '', error_message)
        cleaned_error = re.sub(r'line \d+', '', cleaned_error)
        
        # استخراج الكلمات المهمة
        words = re.findall(r'[A-Za-z]{4,}', cleaned_error)
        
        # تصفية الكلمات الشائعة
        common_words = {'error', 'file', 'line', 'module', 'package', 'object'}
        keywords = [word.lower() for word in words if word.lower() not in common_words]
        
        return keywords
    
    def calculate_solution_relevance(self, content, error_message, code_snippet):
        """حساب مدى صلة المحتوى بالخطأ"""
        score = 0
        
        # مطابقة الكلمات المفتاحية
        keywords = self.extract_keywords_from_error(error_message)
        for keyword in keywords:
            if keyword in content.lower():
                score += 2
        
        # مطابقة أنواع الأخطاء
        error_types = ['TypeError', 'SyntaxError', 'NameError', 'ImportError', 'ValueError']
        for error_type in error_types:
            if error_type in error_message and error_type in content:
                score += 3
        
        # وجود أمثلة كود
        if '```' in content or 'def ' in content:
            score += 2
        
        # وجود حلول عملية
        solution_indicators = ['solution', 'fix', 'resolve', 'correct', 'solve', 'حل', 'إصلاح']
        for indicator in solution_indicators:
            if indicator in content.lower():
                score += 1
        
        return score
    
    def extract_solution_from_content(self, content, error_message):
        """استخراج الحل من المحتوى"""
        # البحث عن أقسام الحلول
        solution_patterns = [
            r'[Ss]olution:\s*(.*?)(?=\n\n|\n[A-Z]|\Z)',
            r'[Ff]ix:\s*(.*?)(?=\n\n|\n[A-Z]|\Z)',
            r'[Tt]o resolve.*?:\s*(.*?)(?=\n\n|\n[A-Z]|\Z)',
            r'الحل:\s*(.*?)(?=\n\n|\n[أ-ي]|\Z)'
        ]
        
        for pattern in solution_patterns:
            match = re.search(pattern, content, re.DOTALL)
            if match:
                return match.group(1).strip()
        
        # إذا لم يوجد قسم حلول واضح، استخدم الفقرات القريبة من الكلمات المفتاحية
        paragraphs = content.split('\n\n')
        for para in paragraphs:
            if any(keyword in para.lower() for keyword in self.extract_keywords_from_error(error_message)):
                if len(para) > 50 and len(para) < 500:
                    return para
        
        # استخدام بداية المحتوى كحل عام
        return content[:300] + '...' if len(content) > 300 else content
    
    def analyze_with_patterns(self, error_message, code_snippet):
        """التحليل باستخدام أنماط البرمجة"""
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        cursor.execute('SELECT pattern_name, pattern_description, use_cases FROM programming_patterns')
        patterns = cursor.fetchall()
        
        for pattern_name, description, use_cases in patterns:
            # البحث عن علاقة بين النمط والخطأ
            if self.pattern_matches_error(pattern_name, description, error_message, code_snippet):
                solution = f"نمط {pattern_name}: {description}\n\n حالات الاستخدام: {use_cases}"
                
                conn.close()
                return {
                    'solution': solution,
                    'confidence': 0.75,
                    'source': 'programming_patterns',
                    'pattern_applied': pattern_name
                }
        
        conn.close()
        return None
    
    def pattern_matches_error(self, pattern_name, description, error_message, code_snippet):
        """التحقق من تطابق النمط مع الخطأ"""
        pattern_lower = pattern_name.lower()
        error_lower = error_message.lower()
        code_lower = code_snippet.lower()
        
        # أنماط مرتبطة بأنواع أخطاء محددة
        pattern_error_mapping = {
            'function': ['NameError', 'TypeError'],
            'conditional_logic': ['SyntaxError', 'IndentationError'],
            'loop_pattern': ['IndexError', 'ValueError']
        }
        
        # التحقق من نوع الخطأ
        for error_type in pattern_error_mapping.get(pattern_lower, []):
            if error_type in error_message:
                return True
        
        # التحقق من وجود كلمات مفتاحية في الوصف
        keywords = pattern_name.split('_') + description.lower().split()
        for keyword in keywords:
            if len(keyword) > 4 and (keyword in error_lower or keyword in code_lower):
                return True
        
        return False
    
    def generate_knowledge_backed_solution(self, error_message, context):
        """توليد حل مدعوم بالمعرفة العامة"""
        # البحث عن معلومات عامة حول نوع الخطأ
        error_type = self.extract_error_type(error_message)
        
        general_advice = {
            'SyntaxError': [
                "تحقق من بناء الجملة باستخدام مصحح الأخطاء في بيئة التطوير",
                "راجع وثائق Python للقواعد النحوية الصحيحة",
                "جرب تقسيم الكود إلى أجزاء أصغر للعزل"
            ],
            'NameError': [
                "تحقق من تهجئة الأسماء والمتغيرات",
                "تأكد من استيراد المكتبات والوحدات اللازمة", 
                "تحقق من نطاق المتغيرات (محلي/عالمي)"
            ],
            'TypeError': [
                "تحقق من أنواع البيانات والتأكد من التوافق",
                "استخدم functions مثل type() و isinstance() للتحقق من الأنواع",
                "راجع وثائق الدوال لمتطلبات أنواع المدخلات"
            ],
            'ImportError': [
                "تأكد من تثبيت المكتبات: pip list",
                "تحقق من اسم الوحدة وطريقة الاستيراد",
                "تأكد من مسار Python (sys.path)"
            ]
        }
        
        advice = general_advice.get(error_type, [
            "ابحث عن الخطأ في Stack Overflow أو وثائق Python الرسمية",
            "جرب البحث باستخدام رسالة الخطأ الدقيقة",
            "استخدم print() debugging لتتبع تدفق البرنامج",
            "تحقق من تحديثات المكتبات وإصدارات Python"
        ])
        
        return {
            'solution': " | ".join(advice),
            'confidence': 0.6,
            'source': 'general_knowledge',
            'error_type': error_type,
            'recommendation': 'search_online'
        }
    
    def extract_error_type(self, error_message):
        """استخراج نوع الخطأ من الرسالة"""
        error_types = ['SyntaxError', 'NameError', 'TypeError', 'ImportError', 
                      'ValueError', 'IndexError', 'KeyError', 'AttributeError',
                      'FileNotFoundError', 'IndentationError']
        
        for error_type in error_types:
            if error_type in error_message:
                return error_type
        
        return 'UnknownError'
    
    def learn_from_resolution(self, error_message, solution_used, success=True):
        """التعلم من الحلول الناجحة"""
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        # البحث عن النمط المطابق
        cursor.execute('SELECT error_pattern FROM debug_solutions')
        existing_patterns = [row[0] for row in cursor.fetchall()]
        
        pattern_found = None
        for pattern in existing_patterns:
            if re.search(pattern, error_message, re.IGNORECASE):
                pattern_found = pattern
                break
        
        if pattern_found and success:
            # تحديث معدل النجاح للنمط الموجود
            cursor.execute('''
                UPDATE debug_solutions 
                SET success_rate = ((success_rate * usage_count) + 1) / (usage_count + 1),
                    usage_count = usage_count + 1
                WHERE error_pattern = ?
            ''', (pattern_found,))
        
        elif not pattern_found and success:
            # إضافة نمط جديد
            error_type = self.extract_error_type(error_message)
            new_pattern = self.generate_pattern_from_error(error_message)
            
            if new_pattern:
                cursor.execute('''
                    INSERT INTO debug_solutions 
                    (error_pattern, solution, category, confidence_score, success_rate, usage_count)
                    VALUES (?, ?, ?, ?, ?, ?)
                ''', (new_pattern, solution_used, error_type.lower(), 0.8, 1.0, 1))
        
        conn.commit()
        conn.close()
        
        print("✅ تم تحديث المعرفة بناءً على الحل الناجح")
    
    def generate_pattern_from_error(self, error_message):
        """توليد نمط من رسالة الخطأ"""
        # تبسيط رسالة الخطأ لنمط قابل لإعادة الاستخدام
        simplified = re.sub(r'File ".*?"', 'File ".*"', error_message)
        simplified = re.sub(r'line \d+', 'line \\d+', simplified)
        simplified = re.sub(r"'[^']*'", "'.*'", simplified)
        simplified = re.sub(r'"[^"]*"', '".*"', simplified)
        
        return simplified if len(simplified) > 20 else None
    
    def generate_performance_report(self):
        """توليد تقرير عن أداء الخبير المدعوم بالمعرفة"""
        conn = sqlite3.connect(self.knowledge_db)
        cursor = conn.cursor()
        
        cursor.execute('SELECT COUNT(*) FROM debug_solutions')
        total_solutions = cursor.fetchone()[0]
        
        cursor.execute('SELECT AVG(confidence_score) FROM debug_solutions')
        avg_confidence = cursor.fetchone()[0] or 0
        
        cursor.execute('SELECT AVG(success_rate) FROM debug_solutions WHERE usage_count > 0')
        avg_success = cursor.fetchone()[0] or 0
        
        cursor.execute('SELECT COUNT(*) FROM web_knowledge')
        web_knowledge_items = cursor.fetchone()[0]
        
        conn.close()
        
        report = {
            'report_date': datetime.now().isoformat(),
            'total_debug_solutions': total_solutions,
            'average_confidence': f"{avg_confidence:.1%}",
            'average_success_rate': f"{avg_success:.1%}",
            'web_knowledge_items': web_knowledge_items,
            'enhancement_level': 'knowledge_enhanced'
        }
        
        return report

def main():
    expert = KnowledgeDebugExpert()
    
    print("🤖 Knowledge-Enhanced Debug Expert")
    print("=" * 50)
    
    # اختبار الأخطاء المختلفة
    test_errors = [
        "ModuleNotFoundError: No module named 'requests'",
        "SyntaxError: invalid syntax near line 10",
        "NameError: name 'calculate_total' is not defined",
        "TypeError: can only concatenate str (not 'int') to str",
        "FileNotFoundError: [Errno 2] No such file or directory: 'config.yaml'"
    ]
    
    print("🧪 يختبر الأخطاء مع المعرفة المحسنة...")
    
    for i, error in enumerate(test_errors, 1):
        print(f"\n🔍 الاختبار {i}: {error}")
        solution = expert.analyze_error_with_knowledge(error)
        
        if solution:
            print(f"💡 الحل: {solution['solution']}")
            print(f"📊 المصدر: {solution['source']} | الثقة: {solution['confidence']:.0%}")
            
            # محاكاة نجاح الحل للتعلم
            expert.learn_from_resolution(error, solution['solution'], success=True)
    
    # تقرير الأداء
    print(f"\n📈 تقرير أداء الخبير المدعوم بالمعرفة:")
    report = expert.generate_performance_report()
    for key, value in report.items():
        print(f"   {key}: {value}")

if __name__ == "__main__":
    main()
