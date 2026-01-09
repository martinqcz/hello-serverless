#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Deploying infrastructure with AWS SAM..."
cd ..

# Ensure artifacts exist
if [ ! -f "hello-backend/build/libs/hello-backend-0.1-lambda.zip" ]; then
  echo "❌ Backend artifact not found. Run ./build-backend.sh first"
  exit 1
fi

cd infra

# Validate template
echo "🔍 Validating SAM template..."
sam validate

# Deploy with guided prompts (first time) or samconfig.toml
if [ ! -f "samconfig.toml" ]; then
  echo "📝 Running guided deployment (first time setup)..."
  sam deploy --guided
else
  echo "📝 Deploying with samconfig.toml..."
  sam deploy
fi

echo ""
echo "✅ Infrastructure deployment complete!"
echo "📋 Next steps:"
echo "   1. Note the CloudFrontDomain output from SAM"
echo "   2. Configure DNS: hello.qapil.com CNAME → <CloudFrontDomain>"
echo "   3. Run ./deploy-frontend.sh to upload frontend files"
