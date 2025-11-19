#!/bin/bash
echo "📚 تطوير نظام المهارات المتكامل 🚀"
echo "================================="
echo "⏰ $(date)"
echo "📍 $(pwd)"

# تحديث ملف المهارات بكل الـ Skills من الـ PDF
cat > config/skills_tracks_backend_complete.yaml << 'SKILLS'
skills:
  # Phase 0 - أساسيات العمل كمبرمج
  computer_basics:
    name: "أساسيات الكمبيوتر والملفات"
    category: "fundamentals"
    level_min: 0
    level_max: 100
    description: "التعامل مع الملفات، المسارات، الـ ZIP، فك/ضغط، تنصيب برامج"

  terminal_basics:
    name: "أساسيات الـ Terminal"
    category: "fundamentals"
    level_min: 0
    level_max: 100
    description: "أوامر cd, ls, mkdir, rm, python, pip بشكل يومي"

  git_basics:
    name: "أساسيات Git"
    category: "fundamentals"
    level_min: 0
    level_max: 100
    description: "git init / add / commit / push / clone + الـ repo والـ branch"

  # Phase 1 - أساسيات بايثون
  python_syntax_basics:
    name: "تركيب لغة بايثون"
    category: "python"
    level_min: 0
    level_max: 100
    description: "متغيرات، أنواع بيانات، عمليات منطقية وحسابية"

  python_control_flow:
    name: "التحكم في سير التنفيذ"
    category: "python"
    level_min: 0
    level_max: 100
    description: "if / elif / else + for / while + فهم indentation"

  python_functions_basics:
    name: "الدوال الأساسية"
    category: "python"
    level_min: 0
    level_max: 100
    description: "تعريف دالة parameters, return, scope بسيط"

  python_collections_basics:
    name: "التراكيب (قوائم، قواميس، مجموعات)"
    category: "python"
    level_min: 0
    level_max: 100
    description: "list / dict / set / tuple + العمليات الأساسية عليهم"

  # Phase 2 - بايثون المتقدمة للمشاريع
  python_oop_basics:
    name: "أساسيات الكائنات"
    category: "python"
    level_min: 0
    level_max: 100
    description: "class / object / init / attributes / methods"

  python_errors_handling:
    name: "التعامل مع الأخطاء"
    category: "python"
    level_min: 0
    level_max: 100
    description: "try/except/finally + raise + فهم Traceback"

  python_modules_packages:
    name: "الوحدات والحزم"
    category: "python"
    level_min: 0
    level_max: 100
    description: "import / from / إنشاء ملف module استخدام مكتبات خارجية"

  python_venv_pip:
    name: "بيئات العمل الافتراضية"
    category: "python"
    level_min: 0
    level_max: 100
    description: "venv / pip / requirements.txt"

  # Phase 3 - أساسيات الـ Backend Web
  web_http_fundamentals:
    name: "أساسيات HTTP"
    category: "backend"
    level_min: 0
    level_max: 100
    description: "request/response, methods (GET/POST/PUT/DELETE), status codes"

  rest_api_concepts:
    name: "مفاهيم REST API"
    category: "backend"
    level_min: 0
    level_max: 100
    description: "resources, endpoints, JSON, stateless"

  backend_framework_intro:
    name: "التعرف على إطار عمل Backend"
    category: "backend"
    level_min: 0
    level_max: 100
    description: "اختيار واحد FastAPI أو Django وفهم فكرة المشروع"

  request_response_handling:
    name: "التعامل مع الطلب/الاستجابة"
    category: "backend"
    level_min: 0
    level_max: 100
    description: "JSON بسيط، إرجاع"

tracks:
  backend_junior_complete:
    name: "مسار المطور الخلفي المبتدئ (كامل)"
    description: "مسار متكامل لتطوير مهارات Backend من الصفر للمستوى المتوسط"
    phases:
      - phase: "أساسيات العمل كمبرمج"
        skills: ["computer_basics", "terminal_basics", "git_basics"]
        order: 1
        
      - phase: "أساسيات بايثون"
        skills: ["python_syntax_basics", "python_control_flow", "python_functions_basics", "python_collections_basics"]
        order: 2
        
      - phase: "بايثون المتقدمة للمشاريع"
        skills: ["python_oop_basics", "python_errors_handling", "python_modules_packages", "python_venv_pip"]
        order: 3
        
      - phase: "أساسيات الـ Backend Web"
        skills: ["web_http_fundamentals", "rest_api_concepts", "backend_framework_intro", "request_response_handling"]
        order: 4

SKILLS

echo "✅ تم إنشاء نظام المهارات المتكامل!"
echo "📊 إحصائيات:"
echo "   - 15 مهارة متكاملة"
echo "   - 4 مراحل تدريبية"
echo "   - مسار Backend Junior كامل"
