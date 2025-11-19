"""
إضافة metadata قابلة للتطبيق للدروس
"""
import json
import os
from pathlib import Path

def enhance_lessons():
    lessons_dir = Path("ai/memory/lessons")
    
    for lesson_file in lessons_dir.glob("*.json"):
        with open(lesson_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # إضافة metadata للتطبيق إذا لم تكن موجودة
        if 'meta' not in data or not data['meta']:
            data['meta'] = {
                'target': {'type': 'config', 'path': 'config/factory.yaml'},
                'action': 'update_yaml',
                'params': {'performance.learning_rate': 0.1},
                'conditions': {'phase': 'phase_stable_reference'}
            }
            
            with open(lesson_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            print(f"✅ تم تحسين: {lesson_file.name}")

if __name__ == "__main__":
    enhance_lessons()
