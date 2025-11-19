#!/usr/bin/env python3
"""
تحسين عرض الدروس في التقرير
"""
import json
from pathlib import Path

def enhance_lessons_display():
    lessons_dir = Path("ai/memory/lessons")
    
    for lesson_file in lessons_dir.glob("*.json"):
        try:
            with open(lesson_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # إضافة وصف مفقود إذا كان موجوداً في البيانات
            if isinstance(data, dict) and 'body' in data and not data.get('description'):
                data['description'] = data['body'][:100] + '...' if len(data['body']) > 100 else data['body']
                
                with open(lesson_file, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                print(f"✅ تم تحسين: {lesson_file.name}")
                
        except Exception as e:
            print(f"⚠️ خطأ في {lesson_file}: {e}")

if __name__ == "__main__":
    enhance_lessons_display()
