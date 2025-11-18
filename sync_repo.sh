#!/usr/bin/env bash

echo "🚀 بدء مزامنة Hyper Factory مع GitHub..."

cd /root/hyper-factory

# عمل .gitignore
cat > .gitignore << 'GITIGNORE'
__pycache__/
*.pyc
*.pyo
.env
venv/
logs/
reports/
ai/datasets/
ai/pdfs/
*.log
.DS_Store
.idea/
.vscode/
GITIGNORE

# عمل README
cat > README.md << 'README'
# 🏭 Hyper Factory

منصة لبناء مساعدين أذكياء.

## التشغيل:
\`\`\`bash
./scripts/core/ffactory.sh init
./scripts/core/ffactory.sh start backend_coach
\`\`\`

http://localhost:9090
README

# تهيئة Git
if [ ! -d ".git" ]; then
    git init
    git remote add origin https://github.com/fatimatofatima/hyper-factory
    git branch -M main
fi

# إضافة الملفات
git add .
git commit -m "تحديث: $(date +'%Y-%m-%d %H:%M:%S')" || true

# رفع للتخزين
git push -f origin main

echo "✅ تم المزامنة!"
