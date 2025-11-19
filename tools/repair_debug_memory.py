#!/usr/bin/env python3
"""
إصلاح ذاكرة Debug Expert
"""

import json
import os

def repair_debug_memory():
    memory_file = "ai/memory/debug_cases.json"
    os.makedirs("ai/memory", exist_ok=True)
    
    print("🔧 يصلح ذاكرة Debug Expert...")
    
    # إذا كان الملف تالفاً أو غير موجود، ننشئه
    if not os.path.exists(memory_file):
        initial_data = []
        with open(memory_file, 'w') as f:
            json.dump(initial_data, f, indent=2)
        print("✅ تم إنشاء ملف الذاكرة الجديد")
        return
    
    # إذا كان الملف موجوداً، نفحصه ونصلحه
    try:
        with open(memory_file, 'r') as f:
            content = f.read().strip()
            
        if not content:
            # ملف فارغ
            with open(memory_file, 'w') as f:
                json.dump([], f, indent=2)
            print("✅ تم إصلاح الملف الفارغ")
            
        elif content.startswith('{'):
            # الملف يحتوي على object بدلاً من array
            fixed_data = [json.loads(content)] if content else []
            with open(memory_file, 'w') as f:
                json.dump(fixed_data, f, indent=2)
            print("✅ تم تحويل Object إلى Array")
            
        else:
            # محاولة تحميل البيانات العادية
            data = json.loads(content)
            if isinstance(data, dict):
                # إذا كانت بيانات على شكل dict، نحولها إلى array
                fixed_data = [data]
                with open(memory_file, 'w') as f:
                    json.dump(fixed_data, f, indent=2)
                print("✅ تم إصلاح تنسيق البيانات")
            else:
                print("✅ البيانات سليمة")
                
    except json.JSONDecodeError as e:
        print(f"❌ خطأ في تنسيق JSON: {e}")
        # إنشاء ملف جديد
        with open(memory_file, 'w') as f:
            json.dump([], f, indent=2)
        print("✅ تم إعادة إنشاء الملف")
    
    except Exception as e:
        print(f"❌ خطأ غير متوقع: {e}")
        with open(memory_file, 'w') as f:
            json.dump([], f, indent=2)
        print("✅ تم إعادة إنشاء الملف كإجراء وقائي")

if __name__ == "__main__":
    repair_debug_memory()
