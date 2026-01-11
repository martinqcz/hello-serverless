#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./deploy-app.sh [env]
#
# Examples:
#   ./deploy-app.sh dev
#   ./deploy-app.sh prod
#
# Domain names are configured in ./env-config.sh

# Load environment configuration
source ./env-config.sh

# Parse arguments
env="${1:-}"

if [[ -z "$env" ]]; then
  echo "❌ Usage: $0 [env]"
  echo "Valid environments: ${!ENV_DOMAINS[@]}"
  exit 1
fi

# Validate environment
if ! validate_env "$env"; then
  exit 1
fi

# Get domain from configuration
domain=$(get_domain "$env")

echo "Environment: $env"
echo "Domain: $domain"
echo ""

echo "🚀 Deploying infrastructure with AWS SAM..."
cd ../infra

# Ensure artifacts exist
if [ ! -f "../hello-backend/build/libs/hello-backend-0.1-lambda.zip" ]; then
  echo "❌ Backend artifact not found. Run ./build-backend.sh first"
  exit 1
fi

# Validate template
echo "🔍 Validating SAM template..."
sam validate --template-file app-stack.yaml

app_stack="${STACK_BASE_NAME}-app-${env}"
cert_stack="${STACK_BASE_NAME}-cert-${env}"

# Allow overriding cert stack name via env var if you want:
cert_stack="${CERT_STACK_NAME:-$cert_stack}"

cert_arn="$(
  aws cloudformation describe-stacks \
    --region "${CERT_REGION}" \
    --stack-name "${cert_stack}" \
    --query "Stacks[0].Outputs[?OutputKey=='CertificateArn'].OutputValue | [0]" \
    --output text
)"

if [[ -z "${cert_arn}" || "${cert_arn}" == "None" ]]; then
  echo "ERROR: Could not read CertificateArn from cert stack '${cert_stack}' in ${CERT_REGION}."
  echo "Run: ./deploy-cert.sh ${domain} ${cert_stack}"
  exit 1
fi

cert_status="$(
  aws acm describe-certificate \
    --region "${CERT_REGION}" \
    --certificate-arn "${cert_arn}" \
    --query "Certificate.Status" \
    --output text
)"

if [[ "${cert_status}" != "ISSUED" ]]; then
  echo "ERROR: ACM certificate is not ISSUED yet."
  echo "Certificate ARN: ${cert_arn}"
  echo "Current status: ${cert_status}"
  echo ""
  echo "If status is PENDING_VALIDATION, make sure the DNS CNAME record is added."
  echo "You can re-check validation records with:"
  echo "  aws acm describe-certificate --region ${CERT_REGION} --certificate-arn ${cert_arn} \\"
  echo "    --query \"Certificate.DomainValidationOptions[*].ResourceRecord\""
  exit 1
fi

echo "Deploying app stack to ${APP_REGION}: ${app_stack}"
echo "Certificate ARN: ${cert_arn}"
echo "Domain: ${domain}"
echo "Environment: ${env}"

sam deploy \
  --template-file app-stack.yaml \
  --stack-name "${app_stack}" \
  --region "${APP_REGION}" \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset \
  --parameter-overrides \
    DomainName="${domain}" \
    Environment="${env}" \
    CertificateArn="${cert_arn}" || {
  echo "Deployment failed. Checking changeset details..."
  CHANGESET_NAME=$(aws cloudformation list-change-sets --stack-name "${app_stack}" --region "${APP_REGION}" --query "Summaries[0].ChangeSetName" --output text 2>&1)
  if [[ -n "$CHANGESET_NAME" && "$CHANGESET_NAME" != "None" ]]; then
    echo "Latest changeset: $CHANGESET_NAME"
    aws cloudformation describe-change-set --change-set-name "$CHANGESET_NAME" --stack-name "${app_stack}" --region "${APP_REGION}" --query "StatusReason" --output text
  fi
  exit 1
}

echo ""
echo "✅ Infrastructure deployment complete!"
echo "📋 Next steps:"
echo "   1. Note the CloudFrontDomain output from SAM"
echo "   2. Configure DNS: ${domain} CNAME → <CloudFrontDomain>"
echo "   3. Run: ./deploy-frontend.sh ${env}"
exit 0
