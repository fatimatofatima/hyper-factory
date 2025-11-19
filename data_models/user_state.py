"""
نموذج حالة المستخدم - Hyper Factory
"""
from pydantic import BaseModel
from typing import Dict, List, Optional
from datetime import datetime

class UserSkillState(BaseModel):
    user_id: str
    current_level: str
    skills: Dict[str, float]  # مهارة -> مستوى
    learning_path: List[str]
    last_activity: datetime
    performance_metrics: Dict[str, float]
    
    def update_skill(self, skill: str, level: float):
        self.skills[skill] = level
        self.last_activity = datetime.now()
