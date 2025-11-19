#!/usr/bin/env python3
"""
مراقب النظام - يتتبع صحة النظام تلقائياً
"""

import os
import sqlite3
import json
import psutil
from datetime import datetime

class SystemGuardian:
    def __init__(self):
        self.monitor_file = "logs/diagnostics/system_health.json"
        self.knowledge_db = "data/knowledge/knowledge.db"
        os.makedirs("logs/diagnostics", exist_ok=True)
    
    def check_system_health(self):
        """فحص صحة النظام الشاملة"""
        print("🔍 فحص صحة النظام...")
        
        health_report = {
            "timestamp": datetime.now().isoformat(),
            "disk_usage": self.get_disk_usage(),
            "memory_usage": self.get_memory_usage(),
            "knowledge_db": self.check_knowledge_db(),
            "essential_files": self.check_essential_files(),
            "active_agents": self.get_active_agents(),
            "system_load": self.get_system_load()
        }
        
        # حفظ التقرير
        with open(self.monitor_file, 'w') as f:
            json.dump(health_report, f, indent=2)
        
        return health_report
    
    def get_disk_usage(self):
        """الحصول على استخدام القرص"""
        try:
            usage = psutil.disk_usage('.').percent
            return f"{usage:.1f}%"
        except:
            return "غير متاح"
    
    def get_memory_usage(self):
        """الحصول على استخدام الذاكرة"""
        try:
            usage = psutil.virtual_memory().percent
            return f"{usage:.1f}%"
        except:
            return "غير متاح"
    
    def check_knowledge_db(self):
        """فحص قاعدة المعرفة"""
        try:
            if not os.path.exists(self.knowledge_db):
                return {"status": "error", "message": "قاعدة المعرفة غير موجودة"}
            
            conn = sqlite3.connect(self.knowledge_db)
            cursor = conn.cursor()
            
            # فحص الجداول الأساسية
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [row[0] for row in cursor.fetchall()]
            
            essential_tables = ['debug_solutions', 'web_knowledge', 'system_patterns']
            missing_tables = [t for t in essential_tables if t not in tables]
            
            # فحص السجلات
            total_records = 0
            for table in tables:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                total_records += cursor.fetchone()[0]
            
            conn.close()
            
            if missing_tables:
                return {
                    "status": "warning", 
                    "message": f"جداول مفقودة: {missing_tables}",
                    "tables": len(tables),
                    "records": total_records
                }
            
            return {
                "status": "healthy", 
                "message": f"قاعدة معرفة سليمة ({len(tables)} جدول, {total_records} سجل)",
                "tables": len(tables),
                "records": total_records
            }
            
        except Exception as e:
            return {"status": "error", "message": f"خطأ في قاعدة البيانات: {e}"}
    
    def check_essential_files(self):
        """فحص الملفات الأساسية"""
        essential_files = [
            "hf_master_dashboard.sh",
            "data/knowledge/knowledge.db",
            "tools/hf_debug_expert_enhanced.py",
            "config/agents.yaml"
        ]
        
        results = {}
        for file in essential_files:
            exists = os.path.exists(file)
            results[file] = {
                "exists": exists,
                "size": os.path.getsize(file) if exists else 0
            }
        
        return results
    
    def get_active_agents(self):
        """الحصول على العوامل النشطة"""
        try:
            agent_processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                try:
                    cmdline = proc.info['cmdline'] or []
                    if any('python' in str(arg).lower() for arg in cmdline):
                        if any('agent' in str(arg).lower() or 'hf_' in str(arg).lower() for arg in cmdline):
                            agent_processes.append({
                                'pid': proc.info['pid'],
                                'name': proc.info['name'],
                                'cmd': ' '.join(cmdline[:2])  # أول أمرين فقط
                            })
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            return len(agent_processes)
        except:
            return 0
    
    def get_system_load(self):
        """الحصول على حمل النظام"""
        try:
            load = os.getloadavg()
            return f"{load[0]:.2f}, {load[1]:.2f}, {load[2]:.2f}"
        except:
            return "غير متاح"
    
    def generate_report(self):
        """توليد تقرير مفصل"""
        report = self.check_system_health()
        
        print("📊 تقرير صحة النظام الشامل:")
        print("=" * 50)
        print(f"⏰ الوقت: {report['timestamp']}")
        print(f"💾 استخدام القرص: {report['disk_usage']}")
        print(f"🧠 استخدام الذاكرة: {report['memory_usage']}")
        print(f"📊 حمل النظام: {report['system_load']}")
        print(f"🤖 العوامل النشطة: {report['active_agents']}")
        
        # تفاصيل قاعدة المعرفة
        kb_status = report['knowledge_db']
        status_icon = "✅" if kb_status['status'] == 'healthy' else "⚠️" if kb_status['status'] == 'warning' else "❌"
        print(f"{status_icon} قاعدة المعرفة: {kb_status['message']}")
        
        # الملفات الأساسية
        print("\n📁 الملفات الأساسية:")
        for file, info in report['essential_files'].items():
            icon = "✅" if info['exists'] else "❌"
            size = f"({info['size']} bytes)" if info['exists'] else ""
            print(f"   {icon} {file} {size}")

if __name__ == "__main__":
    guardian = SystemGuardian()
    guardian.generate_report()
