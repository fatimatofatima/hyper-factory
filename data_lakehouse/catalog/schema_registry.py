"""
سجل المخططات - تنظيم البيانات الحالية
"""
class SchemaRegistry:
    def __init__(self):
        self.schemas = {}
    
    def register_existing_data(self):
        """تسجيل البيانات الموجودة في data/"""
        return {
            "inbox": {"format": "raw", "count": "2 files"},
            "raw": {"format": "raw", "count": "2 files"}, 
            "processed": {"format": "processed", "count": "2 files"},
            "semantic": {"format": "semantic", "count": "3 files"},
            "serving": {"format": "serving", "count": "1 file"}
        }

registry = SchemaRegistry()
print("✅ تم إنشاء سجل المخططات")
