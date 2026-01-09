#!/usr/bin/env bash
set -euo pipefail

echo "🗑️  Removing frontend from S3..."
cd ..

# Get stack outputs
STACK_NAME="hello-serverless"
REGION="us-east-1"

echo "🔍 Fetching stack outputs..."
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='FrontendBucketName'].OutputValue" \
  --output text 2>/dev/null || echo "")

if [ -z "$BUCKET_NAME" ]; then
  echo "⚠️  Stack not found or bucket already deleted"
  exit 0
fi

echo "🗑️  Emptying S3 bucket: $BUCKET_NAME"

# Delete all object versions (bucket has versioning enabled)
echo "📦 Deleting all object versions..."
aws s3api list-object-versions \
  --bucket "$BUCKET_NAME" \
  --query 'Versions[].{Key:Key,VersionId:VersionId}' \
  --output text | \
while read -r key version; do
  if [ -n "$key" ] && [ -n "$version" ]; then
    echo "  Deleting: $key (version: $version)"
    aws s3api delete-object \
      --bucket "$BUCKET_NAME" \
      --key "$key" \
      --version-id "$version" >/dev/null
  fi
done

# Delete all delete markers
echo "🏷️  Deleting all delete markers..."
aws s3api list-object-versions \
  --bucket "$BUCKET_NAME" \
  --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' \
  --output text | \
while read -r key version; do
  if [ -n "$key" ] && [ -n "$version" ]; then
    echo "  Deleting marker: $key (version: $version)"
    aws s3api delete-object \
      --bucket "$BUCKET_NAME" \
      --key "$key" \
      --version-id "$version" >/dev/null
  fi
done

echo ""
echo "✅ Frontend bucket emptied successfully!"
echo "📋 Run ./undeploy-infrastructure.sh to remove all infrastructure"
