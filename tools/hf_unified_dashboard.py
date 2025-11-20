#!/usr/bin/env python3
import sqlite3
import json
import os
from datetime import datetime

class UnifiedDashboard:
    def __init__(self):
        self.db_path = "/root/hyper-factory/data/factory/factory.db"
        self.dashboard_file = "/root/hyper-factory/ai/monitoring/unified_dashboard.json"
        
    def generate_dashboard(self):
        """توليد لوحة تحكم موحدة"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        dashboard_data = {
            "timestamp": datetime.now().isoformat(),
            "overview": {},
            "agents": [],
            "tasks": {},
            "performance": {},
            "alerts": []
        }
        
        # نظرة عامة
        cursor.execute("SELECT COUNT(*) FROM agents WHERE status='active'")
        dashboard_data["overview"]["active_agents"] = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM tasks")
        dashboard_data["overview"]["total_tasks"] = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM tasks WHERE status='done'")
        done_tasks = cursor.fetchone()[0]
        dashboard_data["overview"]["completion_rate"] = (done_tasks / dashboard_data["overview"]["total_tasks"] * 100) if dashboard_data["overview"]["total_tasks"] > 0 else 0
        
        # بيانات العوامل
        cursor.execute("""
            SELECT a.id, a.name, a.display_name, a.success_rate, a.total_runs,
                   COUNT(t.id) as assigned_tasks,
                   (SELECT COUNT(*) FROM feedback_data f WHERE f.agent_id = a.id) as feedback_count
            FROM agents a
            LEFT JOIN tasks t ON a.id = t.agent_id AND t.status = 'assigned'
            WHERE a.status = 'active'
            GROUP BY a.id
            ORDER BY a.success_rate DESC
        """)
        
        for row in cursor.fetchall():
            agent_id, name, display_name, success_rate, total_runs, assigned_tasks, feedback_count = row
            dashboard_data["agents"].append({
                "id": agent_id,
                "name": name,
                "display_name": display_name,
                "success_rate": success_rate,
                "total_runs": total_runs,
                "assigned_tasks": assigned_tasks,
                "performance_level": self.get_performance_level(success_rate),
                "efficiency": self.calculate_efficiency(success_rate, total_runs)
            })
        
        # بيانات المهام
        cursor.execute("SELECT status, COUNT(*) FROM tasks GROUP BY status")
        for status, count in cursor.fetchall():
            dashboard_data["tasks"][status] = count
        
        # الإنذارات
        dashboard_data["alerts"] = self.generate_alerts(dashboard_data)
        
        conn.close()
        
        # حفظ لوحة التحكم
        os.makedirs(os.path.dirname(self.dashboard_file), exist_ok=True)
        with open(self.dashboard_file, 'w', encoding='utf-8') as f:
            json.dump(dashboard_data, f, ensure_ascii=False, indent=2)
        
        self.generate_text_dashboard(dashboard_data)
        return dashboard_data
    
    def get_performance_level(self, success_rate):
        if success_rate >= 90: return "ممتاز"
        elif success_rate >= 70: return "جيد جداً"
        elif success_rate >= 50: return "جيد"
        else: return "يحتاج تحسين"
    
    def calculate_efficiency(self, success_rate, total_runs):
        if total_runs == 0: return 0
        return (success_rate * total_runs) / 100
    
    def generate_alerts(self, dashboard_data):
        alerts = []
        
        # إنذار انخفاض الأداء
        if dashboard_data["overview"]["completion_rate"] < 30:
            alerts.append({
                "type": "warning",
                "message": "📉 أداء منخفض: معدل إنجاز المهام أقل من 30%",
                "suggestion": "زيادة عدد العوامل النشطة وتحسين توزيع المهام"
            })
        
        # إنذار طابور طويل
        if dashboard_data["tasks"].get("queued", 0) > 100:
            alerts.append({
                "type": "warning", 
                "message": "📥 طابور طويل: أكثر من 100 مهمة في الانتظار",
                "suggestion": "تشغيل عوامل إضافية وتسريع المعالجة"
            })
        
        # إنذار عوامل غير نشطة
        if dashboard_data["overview"]["active_agents"] < 5:
            alerts.append({
                "type": "critical",
                "message": "👥 عدد قليل من العوامل النشطة",
                "suggestion": "تشغيل المزيد من العوامل لزيادة الإنتاجية"
            })
        
        return alerts
    
    def generate_text_dashboard(self, dashboard_data):
        """توليد لوحة تحكم نصية"""
        text_file = "/root/hyper-factory/reports/dashboard/unified_dashboard.txt"
        os.makedirs(os.path.dirname(text_file), exist_ok=True)
        
        with open(text_file, 'w', encoding='utf-8') as f:
            f.write("🎛️  لوحة تحكم Hyper Factory الموحدة\n")
            f.write("=" * 60 + "\n\n")
            
            f.write("📊 النظرة العامة:\n")
            f.write(f"   👥 العوامل النشطة: {dashboard_data['overview']['active_agents']}\n")
            f.write(f"   🎯 إجمالي المهام: {dashboard_data['overview']['total_tasks']}\n")
            f.write(f"   📈 معدل الإنجاز: {dashboard_data['overview']['completion_rate']:.1f}%\n\n")
            
            f.write("🏆 أفضل العوامل أداءً:\n")
            f.write("-" * 50 + "\n")
            for i, agent in enumerate(dashboard_data['agents'][:5], 1):
                f.write(f"{i}. {agent['display_name']}\n")
                f.write(f"   📊 نجاح: {agent['success_rate']}% | 🔄 تشغيلات: {agent['total_runs']}\n")
                f.write(f"   🎯 مستوى: {agent['performance_level']} | ⚡ كفاءة: {agent['efficiency']:.1f}\n\n")
            
            f.write("📋 حالة المهام:\n")
            f.write("-" * 30 + "\n")
            for status, count in dashboard_data['tasks'].items():
                status_emoji = {"queued": "⏳", "assigned": "🔄", "done": "✅"}.get(status, "📄")
                f.write(f"   {status_emoji} {status}: {count}\n")
            
            f.write("\n🚨 الإنذارات:\n")
            f.write("-" * 30 + "\n")
            if dashboard_data['alerts']:
                for alert in dashboard_data['alerts']:
                    emoji = "⚠️" if alert['type'] == 'warning' else "🚨"
                    f.write(f"   {emoji} {alert['message']}\n")
                    f.write(f"   💡 الاقتراح: {alert['suggestion']}\n\n")
            else:
                f.write("   ✅ لا توجد إنذارات - النظام يعمل بشكل طبيعي\n")

if __name__ == "__main__":
    dashboard = UnifiedDashboard()
    dashboard.generate_dashboard()
    print("✅ تم تحديث لوحة التحكم الموحدة")
