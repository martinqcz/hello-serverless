#!/usr/bin/env bash
set -euo pipefail

echo "🏗️  Building frontend..."
cd ../hello-frontend

# Install dependencies
bun install

# Type check
echo "🔍 Running type check..."
bun run type-check

# Build production bundle
echo "📦 Building production bundle..."
bun run build

# Verify dist exists
if [ -d "dist" ] && [ -f "dist/index.html" ]; then
  echo "✅ Frontend build successful: $(du -sh dist | cut -f1)"
  echo "📁 Contents:"
  ls -lh dist/
else
  echo "❌ Frontend build failed: dist/ not found or incomplete"
  exit 1
fi
