#!/bin/bash
echo "🔓 فتح قفل قاعدة البيانات..."
cd /root/hyper-factory
fuser -k data/factory/factory.db 2>/dev/null || true
fuser -k data/knowledge/knowledge.db 2>/dev/null || true
rm -f data/factory/factory.db-journal 2>/dev/null || true
rm -f data/knowledge/knowledge.db-journal 2>/dev/null || true
echo "✅ تم فتح القفل"
