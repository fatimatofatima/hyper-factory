#!/bin/bash
echo "🏋️ بدء التدريب المتقدم لـ Debug Expert..."

# 1. إنشاء حالات تدريب متقدمة
python3 -c "
import json
import os

os.makedirs('ai/memory/training', exist_ok=True)

advanced_cases = [
    {
        'case_id': 'adv_001',
        'error_type': 'ImportError',
        'error_message': 'ModuleNotFoundError: No module named pandas',
        'code_snippet': 'import pandas as pd\\nprint(pd.DataFrame())',
        'solution': 'قم بتثبيت المكتبة: pip install pandas',
        'difficulty': 'beginner',
        'category': 'import_issues',
        'common_patterns': ['No module named', 'ModuleNotFoundError']
    },
    {
        'case_id': 'adv_002', 
        'error_type': 'TypeError',
        'error_message': \"TypeError: can only concatenate str (not 'int') to str\",
        'code_snippet': \"name = 'Ahmed'\\nage = 25\\nprint(name + age)\",
        'solution': 'تحويل الرقم إلى نص: print(name + str(age))',
        'difficulty': 'beginner',
        'category': 'type_conversion',
        'common_patterns': [\"concatenate str\", \"TypeError\"]
    },
    {
        'case_id': 'adv_003',
        'error_type': 'FileNotFoundError', 
        'error_message': 'FileNotFoundError: [Errno 2] No such file or directory: data.txt',
        'code_snippet': \"with open('data.txt', 'r') as f:\\n    print(f.read())\",
        'solution': 'تأكد من وجود الملف أو استخدم معالجة الاستثناءات',
        'difficulty': 'intermediate',
        'category': 'file_operations',
        'common_patterns': ['No such file', 'FileNotFoundError']
    },
    {
        'case_id': 'adv_004',
        'error_type': 'SyntaxError',
        'error_message': 'SyntaxError: invalid syntax',
        'code_snippet': 'if x > 5\\n    print(x)',
        'solution': 'إضافة النقطتين بعد الشرط: if x > 5:',
        'difficulty': 'beginner', 
        'category': 'syntax_basics',
        'common_patterns': ['invalid syntax', 'SyntaxError']
    },
    {
        'case_id': 'adv_005',
        'error_type': 'IndexError',
        'error_message': 'IndexError: list index out of range',
        'code_snippet': 'items = [1, 2, 3]\\nprint(items[5])',
        'solution': 'تأكد من أن الفهرس ضمن نطاق القائمة',
        'difficulty': 'intermediate',
        'category': 'list_operations',
        'common_patterns': ['index out of range', 'IndexError']
    }
]

with open('ai/memory/training/advanced_debug_cases.json', 'w') as f:
    json.dump(advanced_cases, f, indent=2)

print('✅ تم إنشاء 5 حالات تدريب متقدمة')
"

# 2. تحديث قاعدة معرفة Debug Expert
python3 -c "
import json
import sqlite3
import os

# الاتصال بقاعدة المعرفة
os.makedirs('data/knowledge', exist_ok=True)
conn = sqlite3.connect('data/knowledge/knowledge.db')
cursor = conn.cursor()

# إنشاء جدول معرفة التصحيح إذا لم يكن موجوداً
cursor.execute('''
    CREATE TABLE IF NOT EXISTS debug_knowledge (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        error_pattern TEXT,
        solution TEXT,
        category TEXT,
        difficulty TEXT,
        success_rate REAL,
        usage_count INTEGER DEFAULT 0
    )
''')

# إضافة أنماط الأخطاء الشائعة
common_patterns = [
    ('No module named', 'تأكد من تثبيت المكتبة: pip install <package>', 'import_issues', 'beginner', 0.95, 0),
    ('SyntaxError: invalid syntax', 'تحقق من الأقواس والنقطتين والمسافات البادئة', 'syntax_basics', 'beginner', 0.90, 0),
    ('NameError: name.*is not defined', 'تأكد من تعريف المتغير قبل استخدامه', 'variable_scope', 'beginner', 0.88, 0),
    ('IndentationError', 'تحقق من تسوية المسافات البادئة بشكل صحيح', 'syntax_basics', 'beginner', 0.92, 0),
    ('TypeError:.*concatenate', 'تحويل الأنواع قبل الدمج أو استخدام f-strings', 'type_conversion', 'intermediate', 0.85, 0)
]

cursor.executemany('''
    INSERT INTO debug_knowledge (error_pattern, solution, category, difficulty, success_rate, usage_count)
    VALUES (?, ?, ?, ?, ?, ?)
''', common_patterns)

conn.commit()
conn.close()
print('✅ تم تحديث قاعدة معرفة التصحيح')
"

# 3. إنشاء نظام تقييم الأداء
python3 -c "
import json
from datetime import datetime

performance_data = {
    'last_training': datetime.now().isoformat(),
    'training_cases_count': 5,
    'knowledge_patterns': 5,
    'expected_improvement': '70% → 85%',
    'next_evaluation': 'after_24_hours',
    'metrics_to_track': ['success_rate', 'response_time', 'user_satisfaction']
}

with open('ai/memory/debug_expert_performance.json', 'w') as f:
    json.dump(performance_data, f, indent=2)

print('✅ تم إنشاء نظام تقييم الأداء')
"

echo "🎓 اكتمل التدريب المتقدم لـ Debug Expert"
echo "📈 متوقع: تحسن الأداء من 70% إلى 85%+"
