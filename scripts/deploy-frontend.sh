#!/usr/bin/env bash
set -euo pipefail

echo "📦 Deploying frontend to S3..."
cd ..

# Get stack outputs
STACK_NAME="hello-serverless"
REGION="us-east-1"

echo "🔍 Fetching stack outputs..."
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendBucketName'].OutputValue" \
  --output text)

DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue" \
  --output text)

if [ -z "$BUCKET_NAME" ] || [ -z "$DISTRIBUTION_ID" ]; then
  echo "❌ Failed to fetch stack outputs. Is the stack deployed?"
  exit 1
fi

echo "📤 Uploading to S3 bucket: $BUCKET_NAME"
aws s3 sync hello-frontend/dist/ "s3://$BUCKET_NAME/" \
  --delete \
  --cache-control "public,max-age=31536000,immutable" \
  --exclude "index.html" \
  --exclude "*.txt"

# Upload index.html with no-cache
echo "📤 Uploading index.html (no cache)..."
aws s3 cp hello-frontend/dist/index.html "s3://$BUCKET_NAME/index.html" \
  --cache-control "no-cache,no-store,must-revalidate" \
  --content-type "text/html"

# Upload robots.txt, favicon if exist
[ -f hello-frontend/dist/robots.txt ] && \
  aws s3 cp hello-frontend/dist/robots.txt "s3://$BUCKET_NAME/robots.txt"
[ -f hello-frontend/dist/favicon.ico ] && \
  aws s3 cp hello-frontend/dist/favicon.ico "s3://$BUCKET_NAME/favicon.ico"

echo "🔄 Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*" \
  --query "Invalidation.Id" \
  --output text

echo ""
echo "✅ Frontend deployment complete!"
echo "🌐 Application URL: https://hello.qapil.com (after DNS propagation)"
