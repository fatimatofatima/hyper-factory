# 🔧 Debug Expert - آلية العمل

## 📋 المدخلات (Inputs):
- كود به أخطاء
- رسالة خطأ (Traceback)
- وصف المشكلة

## 🔄 خطوات المعالجة:

1. **التصنيف (Classification)**:
   ```python
   if "SyntaxError" in error: type = "syntax"
   elif "NameError" in error: type = "name" 
   elif "ImportError" in error: type = "import"
   else: type = "general"

### 🏗️ **عامل System Architect - المهندس المعماري**

```bash
# آلية عمل System Architect  
cat > agents/system_architect/agent_workflow.md <<'EOF'
# 🏗️ System Architect - آلية العمل

## 📋 المدخلات:
- فكرة مشروع
- متطلبات المستخدم
- قيود (وقت، ميزانية، موارد)

## 🔄 خطوات المعالجة:

1. **فهم المتطلبات**:
   - تحليل الهدف التجاري
   - تحديد المستخدمين النهائيين
   - دراسة حالات الاستخدام

2. **التصميم المعماري**:
   ```python
   architecture = {
     "backend": "FastAPI/Django",
     "database": "PostgreSQL/SQLite", 
     "frontend": "React/Streamlit",
     "deployment": "Docker/VPS"
   }

### 👨‍🏫 **عامل Technical Coach - المدرب التقني**

```bash
# آلية عمل Technical Coach
cat > agents/technical_coach/agent_workflow.md <<'EOF'
# 👨‍🏫 Technical Coach - آلية العمل

## 📋 المدخلات:
- مستوى المتدرب الحالي
- الأهداف التعليمية
- الوقت المتاح

## 🔄 خطوات المعالجة:

1. **التقييم الأولي**:
   ```python
   skills_assessment = {
     "python_basics": 65,
     "debugging": 30, 
     "web_development": 10
   }

### 🕷️ **عامل Knowledge Spider - زاحف المعرفة**

```bash
# آلية عمل Knowledge Spider
cat > agents/knowledge_spider/agent_workflow.md <<'EOF'
# 🕷️ Knowledge Spider - آلية العمل

## 📋 المدخلات:
- مصادر معرفة (مواقع، وثائق)
- كلمات مفتاحية للبحث
- تفضيلات التصنيف

## 🔄 خطوات المعالجة:

1. **جمع البيانات**:
   - زحف المصادر المحددة
   - استخراج المحتوى المفيد
   - تصفية المعلومات غير المرغوبة

2. **معالجة المحتوى**:
   ```python
   processed_content = {
     "title": "عنوان المقال",
     "content": "النص الرئيسي", 
     "category": "برمجة/تصحيح",
     "difficulty": "مبتدئ/متقدم"
   }

## 🔄 **4. التكامل بين المكونات**

### 🤝 **كيف تتفاعل المكونات:**

```bash
# نموذج التفاعل بين المكونات
cat > scripts/component_interaction.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "🔄 تفاعل مكونات النظام"
echo "======================"

demonstrate_interaction() {
    # 1. وصول طلب جديد
    echo "📨 1. وصول طلب جديد للمصنع"
    echo '{"user": "مطور", "message": "هذا الخطأ: NameError: name x is not defined"}' > data/inbox/new_requests.json
    
    # 2. السيدر يكتشف الطلب
    echo "⏰ 2. السيدر يكتشف الطلب الجديد"
    ./scripts/master_scheduler.sh
    
    # 3. التوجيه إلى العامل المناسب
    echo "🔀 3. التوجيه إلى Debug Expert"
    ./scripts/factory_manager.sh "هذا الخطأ: NameError: name x is not defined"
    
    # 4. المعالجة والحل
    echo "🔧 4. Debug Expert يعالج المشكلة"
    ./hf_run_debug_expert.sh "هذا الخطأ: NameError: name x is not defined"
    
    # 5. حفظ في الذاكرة
    echo "💾 5. حفظ التجربة في الذاكرة"
    python3 -c "
import json
from datetime import datetime

experience = {
    'timestamp': '$(date)',
    'agent': 'debug_expert',
    'problem': 'NameError: name x is not defined',
    'solution': 'تأكد من تعريف المتغير x قبل استخدامه',
    'learned': True
}

# إضافة إلى سجل التعلم
with open('ai/memory/learning_experiences.jsonl', 'a') as f:
    f.write(json.dumps(experience, ensure_ascii=False) + '\n')
    
print('✅ تم حفظ التجربة للتعلم المستقبلي')
"
    
    # 6. التعلم الآلي
    echo "🧠 6. تحديث أنماط التعلم"
    ./scripts/auto_learning_engine.sh
    
    echo "🎯 اكتمل تفاعل المكونات بنجاح!"
}

demonstrate_interaction
