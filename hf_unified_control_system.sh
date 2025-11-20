#!/bin/bash
echo "🎛️  تشغيل نظام القياس والتحكم الموحد..."

# 1. إنشاء هيكل القياس والتحكم
mkdir -p /root/hyper-factory/ai/feedback
mkdir -p /root/hyper-factory/ai/performance
mkdir -p /root/hyper-factory/ai/monitoring

# 2. إنشاء قاعدة بيانات القياسات
cat > /tmp/create_metrics.sql <<'SQL'
-- جدول قياسات الأداء
CREATE TABLE IF NOT EXISTS performance_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    metric_type TEXT NOT NULL,
    metric_value REAL NOT NULL,
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- جدول التغذية الراجعة
CREATE TABLE IF NOT EXISTS feedback_data (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    task_id INTEGER,
    feedback_score INTEGER,
    feedback_text TEXT,
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP
);

-- جدول القياسات الزمنية
CREATE TABLE IF NOT EXISTS time_series_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric_name TEXT NOT NULL,
    metric_value REAL NOT NULL,
    timestamp TEXT DEFAULT CURRENT_TIMESTAMP
);
SQL

sqlite3 /root/hyper-factory/data/factory/factory.db < /tmp/create_metrics.sql

# 3. إنشاء نظام القياس التلقائي
cat > /root/hyper-factory/tools/hf_performance_monitor.py <<'PYTHON'
#!/usr/bin/env python3
import sqlite3
import time
import json
import os
from datetime import datetime

DB_PATH = "/root/hyper-factory/data/factory/factory.db"
METRICS_FILE = "/root/hyper-factory/ai/performance/live_metrics.json"

def collect_performance_metrics():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # جمع قياسات الأداء
    metrics = {
        "timestamp": datetime.now().isoformat(),
        "agents": {},
        "system": {},
        "tasks": {}
    }
    
    # قياسات العوامل
    cursor.execute("""
        SELECT id, name, success_rate, total_runs, status 
        FROM agents 
        WHERE status = 'active'
    """)
    for agent_id, name, success_rate, total_runs, status in cursor.fetchall():
        metrics["agents"][agent_id] = {
            "name": name,
            "success_rate": success_rate,
            "total_runs": total_runs,
            "status": status,
            "performance_score": calculate_performance_score(success_rate, total_runs)
        }
    
    # قياسات المهام
    cursor.execute("""
        SELECT status, COUNT(*) 
        FROM tasks 
        GROUP BY status
    """)
    for status, count in cursor.fetchall():
        metrics["tasks"][status] = count
    
    # قياسات النظام
    cursor.execute("SELECT COUNT(*) FROM agents WHERE status='active'")
    metrics["system"]["active_agents"] = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM tasks")
    metrics["system"]["total_tasks"] = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM tasks WHERE status='done'")
    done_tasks = cursor.fetchone()[0]
    metrics["system"]["completion_rate"] = (done_tasks / metrics["system"]["total_tasks"] * 100) if metrics["system"]["total_tasks"] > 0 else 0
    
    conn.close()
    return metrics

def calculate_performance_score(success_rate, total_runs):
    """حساب درجة أداء مركبة"""
    if total_runs == 0:
        return 0
    # وزن النجاح + عدد التشغيلات
    return (success_rate * 0.7) + (min(total_runs / 100, 1) * 30)

def save_metrics_to_db(metrics):
    """حفظ القياسات في قاعدة البيانات"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    for agent_id, agent_data in metrics["agents"].items():
        cursor.execute("""
            INSERT INTO performance_metrics (agent_id, metric_type, metric_value, description)
            VALUES (?, 'performance_score', ?, ?)
        """, (agent_id, agent_data["performance_score"], f"أداء {agent_data['name']}"))
    
    # حفظ قياسات النظام
    cursor.execute("""
        INSERT INTO time_series_metrics (metric_name, metric_value)
        VALUES ('completion_rate', ?)
    """, (metrics["system"]["completion_rate"],))
    
    cursor.execute("""
        INSERT INTO time_series_metrics (metric_name, metric_value)
        VALUES ('active_agents', ?)
    """, (metrics["system"]["active_agents"],))
    
    conn.commit()
    conn.close()

def generate_performance_report():
    """توليد تقرير أداء تفاعلي"""
    metrics = collect_performance_metrics()
    save_metrics_to_db(metrics)
    
    # حفظ كملف JSON للويب
    with open(METRICS_FILE, 'w', encoding='utf-8') as f:
        json.dump(metrics, f, ensure_ascii=False, indent=2)
    
    # توليد تقرير نصي
    report_file = "/root/hyper-factory/reports/performance/live_performance_report.txt"
    os.makedirs(os.path.dirname(report_file), exist_ok=True)
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("📊 تقرير أداء Hyper Factory الحي\n")
        f.write("=" * 50 + "\n\n")
        f.write(f"⏰ الوقت: {metrics['timestamp']}\n")
        f.write(f"👥 العوامل النشطة: {metrics['system']['active_agents']}\n")
        f.write(f"🎯 إجمالي المهام: {metrics['system']['total_tasks']}\n")
        f.write(f"📈 معدل الإنجاز: {metrics['system']['completion_rate']:.1f}%\n\n")
        
        f.write("🏆 ترتيب العوامل حسب الأداء:\n")
        f.write("-" * 40 + "\n")
        
        sorted_agents = sorted(metrics["agents"].items(), 
                             key=lambda x: x[1]["performance_score"], 
                             reverse=True)
        
        for i, (agent_id, agent_data) in enumerate(sorted_agents[:10], 1):
            f.write(f"{i}. {agent_data['name']}: {agent_data['performance_score']:.1f} نقطة ")
            f.write(f"({agent_data['success_rate']}% نجاح, {agent_data['total_runs']} تشغيل)\n")
        
        f.write(f"\n📋 حالة المهام:\n")
        f.write(f"   ✅ مكتملة: {metrics['tasks'].get('done', 0)}\n")
        f.write(f"   🔄 قيد التنفيذ: {metrics['tasks'].get('assigned', 0)}\n")
        f.write(f"   ⏳ في الانتظار: {metrics['tasks'].get('queued', 0)}\n")

if __name__ == "__main__":
    generate_performance_report()
    print("✅ تم تحديث قياسات الأداء والتحكم")
PYTHON

chmod +x /root/hyper-factory/tools/hf_performance_monitor.py

# 4. إنشاء نظام التغذية الراجعة
cat > /root/hyper-factory/tools/hf_feedback_system.py <<'PYTHON'
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
PYTHON

chmod +x /root/hyper-factory/tools/hf_feedback_system.py

# 5. إنشاء لوحة التحكم الموحدة
cat > /root/hyper-factory/tools/hf_unified_dashboard.py <<'PYTHON'
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
PYTHON

chmod +x /root/hyper-factory/tools/hf_unified_dashboard.py

# 6. تشغيل النظام الموحد
echo "🚀 تشغيل نظام القياس والتحكم الموحد..."

# تشغيل أنظمة القياس
python3 /root/hyper-factory/tools/hf_performance_monitor.py
python3 /root/hyper-factory/tools/hf_feedback_system.py  
python3 /root/hyper-factory/tools/hf_unified_dashboard.py

# تشغيل العوامل الأساسية
./hf_run_debug_expert.sh &
./hf_run_system_architect.sh &
./hf_run_knowledge_spider.sh &
./hf_run_technical_coach.sh &

# عرض النتائج
echo ""
echo "🎉 نظام القياس والتحكم الموحد يعمل!"
echo ""
echo "📊 لوحة التحكم الموحدة:"
cat /root/hyper-factory/reports/dashboard/unified_dashboard.txt
echo ""
echo "📈 تقرير الأداء:"
cat /root/hyper-factory/reports/performance/live_performance_report.txt | head -20
