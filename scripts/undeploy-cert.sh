#!/usr/bin/env bash
set -euo pipefail

echo "🗑️  Undeploying domain certificate..."
cd ../infra

# Get stack outputs
BASE_NAME="hello"
CERT_REGION="us-east-1"

env="${1:-prod}"

STACK_NAME="${BASE_NAME}-cert-${env}"

# Check if stack exists
echo "🔍 Checking if stack exists..."
STACK_STATUS=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$CERT_REGION" \
  --query "Stacks[0].StackStatus" \
  --output text 2>/dev/null || echo "DOES_NOT_EXIST")

if [ "$STACK_STATUS" = "DOES_NOT_EXIST" ]; then
  echo "⚠️  Stack '$STACK_NAME' does not exist or already deleted"
  exit 0
fi

echo "📦 Found stack: $STACK_NAME (status: $STACK_STATUS)"

echo ""
echo "🗑️  Deleting stack: $STACK_NAME"
sam delete --stack-name "$STACK_NAME" --region "$CERT_REGION" --no-prompts
echo ""
echo "✅ Certificate undeployed successfully!"
echo ""
echo "⚠️  Note: You can remove the CNAME DNS record for ACM certificate verification"
