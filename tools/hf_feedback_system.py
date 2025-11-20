#!/usr/bin/env python3
import sqlite3
import json
import os
from datetime import datetime

DB_PATH = "/root/hyper-factory/data/factory/factory.db"
FEEDBACK_FILE = "/root/hyper-factory/ai/feedback/agent_feedback.json"

class FeedbackSystem:
    def __init__(self):
        self.conn = sqlite3.connect(DB_PATH)
        
    def record_feedback(self, agent_id, task_id, score, text=""):
        """تسجيل تغذية راجعة للعامل"""
        cursor = self.conn.cursor()
        cursor.execute("""
            INSERT INTO feedback_data (agent_id, task_id, feedback_score, feedback_text)
            VALUES (?, ?, ?, ?)
        """, (agent_id, task_id, score, text))
        self.conn.commit()
        
        # تحديث أداء العامل
        self.update_agent_performance(agent_id)
        
    def update_agent_performance(self, agent_id):
        """تحديث أداء العامل بناءً على التغذية الراجعة"""
        cursor = self.conn.cursor()
        
        # حساب متوسط التغذية الراجعة
        cursor.execute("""
            SELECT AVG(feedback_score) 
            FROM feedback_data 
            WHERE agent_id = ?
        """, (agent_id,))
        avg_feedback = cursor.fetchone()[0] or 0
        
        # تحديث نسبة النجاح
        cursor.execute("""
            UPDATE agents 
            SET success_rate = ?, last_seen = ?
            WHERE id = ?
        """, (avg_feedback, datetime.now().isoformat(), agent_id))
        
        self.conn.commit()
        
    def generate_feedback_report(self):
        """توليد تقرير التغذية الراجعة"""
        cursor = self.conn.cursor()
        
        cursor.execute("""
            SELECT a.id, a.name, 
                   AVG(f.feedback_score) as avg_score,
                   COUNT(f.id) as feedback_count
            FROM agents a
            LEFT JOIN feedback_data f ON a.id = f.agent_id
            WHERE a.status = 'active'
            GROUP BY a.id
            ORDER BY avg_score DESC
        """)
        
        feedback_report = {
            "timestamp": datetime.now().isoformat(),
            "agents": []
        }
        
        for agent_id, name, avg_score, feedback_count in cursor.fetchall():
            feedback_report["agents"].append({
                "id": agent_id,
                "name": name,
                "average_score": avg_score or 0,
                "feedback_count": feedback_count,
                "performance_level": self.get_performance_level(avg_score or 0)
            })
        
        # حفظ التقرير
        with open(FEEDBACK_FILE, 'w', encoding='utf-8') as f:
            json.dump(feedback_report, f, ensure_ascii=False, indent=2)
            
        # حفظ تقرير نصي
        text_report = "/root/hyper-factory/reports/feedback/feedback_report.txt"
        os.makedirs(os.path.dirname(text_report), exist_ok=True)
        
        with open(text_report, 'w', encoding='utf-8') as f:
            f.write("📝 تقرير التغذية الراجعة للعوامل\n")
            f.write("=" * 50 + "\n\n")
            
            for agent in feedback_report["agents"]:
                f.write(f"👤 {agent['name']}:\n")
                f.write(f"   📊 متوسط التقييم: {agent['average_score']:.1f}/10\n")
                f.write(f"   🗳️  عدد التقييمات: {agent['feedback_count']}\n")
                f.write(f"   🎯 مستوى الأداء: {agent['performance_level']}\n")
                f.write(f"   {'⭐' * int(agent['average_score'])}\n\n")
    
    def get_performance_level(self, score):
        """تحديد مستوى الأداء"""
        if score >= 9: return "ممتاز 🏆"
        elif score >= 7: return "جيد جداً ⭐⭐⭐⭐"
        elif score >= 5: return "جيد ⭐⭐⭐"
        elif score >= 3: return "مقبول ⭐⭐"
        else: return "يحتاج تحسين ⭐"

if __name__ == "__main__":
    feedback_system = FeedbackSystem()
    feedback_system.generate_feedback_report()
    print("✅ تم تحديث نظام التغذية الراجعة")
