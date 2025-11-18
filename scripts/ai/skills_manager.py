#!/usr/bin/env python3
import os
import json
from typing import Dict, Any

class SkillsManager:
    def __init__(self):
        self.data_path = "ai/datasets/user_skills"
        os.makedirs(self.data_path, exist_ok=True)
    
    def get_skills_state(self, user_id: str) -> Dict[str, Any]:
        file_path = f"{self.data_path}/{user_id}.json"
        try:
            if os.path.exists(file_path):
                with open(file_path, 'r', encoding='utf-8') as f:
                    return json.load(f)
        except Exception as e:
            print(f"⚠️ خطأ في قراءة ملف المهارات: {e}")
        
        # حالة افتراضية إذا المستخدم جديد
        return {
            "user_id": user_id,
            "skills": {
                "python_syntax_basics": 0,
                "python_control_flow": 0,
                "python_functions_basics": 0
            },
            "level": "beginner"
        }
    
    def update_skill(self, user_id: str, skill_id: str, new_score: int) -> Dict[str, Any]:
        try:
            state = self.get_skills_state(user_id)
            state["skills"][skill_id] = new_score
            state["level"] = self._calculate_level(state["skills"])
            
            file_path = f"{self.data_path}/{user_id}.json"
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(state, f, ensure_ascii=False, indent=2)
            
            return state
        except Exception as e:
            print(f"⚠️ خطأ في تحديث المهارة: {e}")
            return {"error": str(e)}
    
    def _calculate_level(self, skills: Dict[str, int]) -> str:
        if not skills:
            return "beginner"
        
        try:
            avg_score = sum(skills.values()) / len(skills)
            if avg_score < 40:
                return "beginner"
            elif avg_score < 70:
                return "intermediate"
            else:
                return "advanced"
        except:
            return "beginner"
