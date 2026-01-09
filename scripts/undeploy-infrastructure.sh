#!/usr/bin/env bash
set -euo pipefail

echo "🗑️  Undeploying infrastructure..."
cd ..

STACK_NAME="hello-serverless"
REGION="us-east-1"

# Check if stack exists
echo "🔍 Checking if stack exists..."
STACK_STATUS=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].StackStatus" \
  --output text 2>/dev/null || echo "DOES_NOT_EXIST")

if [ "$STACK_STATUS" = "DOES_NOT_EXIST" ]; then
  echo "⚠️  Stack '$STACK_NAME' does not exist or already deleted"
  exit 0
fi

echo "📦 Found stack: $STACK_NAME (status: $STACK_STATUS)"

# Empty S3 bucket first (CloudFormation can't delete non-empty buckets)
echo ""
echo "Step 1: Emptying S3 bucket..."
if [ -f "scripts/undeploy-frontend.sh" ]; then
  cd scripts
  ./undeploy-frontend.sh
  cd ..
else
  echo "⚠️  undeploy-frontend.sh not found, attempting to empty bucket manually..."

  BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='FrontendBucketName'].OutputValue" \
    --output text 2>/dev/null || echo "")

  if [ -n "$BUCKET_NAME" ]; then
    echo "🗑️  Emptying bucket: $BUCKET_NAME"
    aws s3 rm "s3://$BUCKET_NAME" --recursive 2>/dev/null || true

    # Handle versioned objects
    aws s3api list-object-versions \
      --bucket "$BUCKET_NAME" \
      --query 'Versions[].{Key:Key,VersionId:VersionId}' \
      --output text 2>/dev/null | \
    while read -r key version; do
      [ -n "$key" ] && [ -n "$version" ] && \
        aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$version" >/dev/null
    done

    aws s3api list-object-versions \
      --bucket "$BUCKET_NAME" \
      --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' \
      --output text 2>/dev/null | \
    while read -r key version; do
      [ -n "$key" ] && [ -n "$version" ] && \
        aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$version" >/dev/null
    done
  fi
fi

# Delete CloudFormation stack
echo ""
echo "Step 2: Deleting CloudFormation stack..."
echo "⚠️  This will delete:"
echo "   - Lambda function (hello-backend-prod)"
echo "   - API Gateway HTTP API"
echo "   - DynamoDB table (hello)"
echo "   - S3 bucket (hello-frontend-*)"
echo "   - CloudFront distribution"
echo "   - All associated IAM roles and policies"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "❌ Undeploy cancelled"
  exit 1
fi

echo ""
echo "🗑️  Deleting stack: $STACK_NAME"
cd infra
sam delete --stack-name "$STACK_NAME" --region "$REGION" --no-prompts

echo ""
echo "✅ Infrastructure undeployed successfully!"
echo ""
echo "📋 Cleanup complete. Resources deleted:"
echo "   ✓ Lambda function"
echo "   ✓ API Gateway"
echo "   ✓ DynamoDB table"
echo "   ✓ S3 bucket"
echo "   ✓ CloudFront distribution"
echo "   ✓ IAM roles"
echo ""
echo "⚠️  Note: CloudFront distribution deletion can take 15-60 minutes to fully complete"
echo "⚠️  Note: ACM certificate for hello.qapil.com was NOT deleted (manual deletion required if needed)"
