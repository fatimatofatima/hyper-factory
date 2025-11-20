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
