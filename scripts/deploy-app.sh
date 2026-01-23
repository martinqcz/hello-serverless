#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./deploy-app.sh [env] [google-client-id] [google-client-secret]
#
# Examples:
#   ./deploy-app.sh dev                             # Credentials from env vars
#   ./deploy-app.sh dev abc123 secret123            # Credentials from args
#
# Environment variables:
#   GOOGLE_CLIENT_ID      - Google OAuth Client ID (required)
#   GOOGLE_CLIENT_SECRET  - Google OAuth Client Secret (required)
#
# Domain names are configured in ./env-config.sh

# Load environment configuration
source ./env-config.sh

# Parse arguments
env="${1:-}"
google_client_id="${2:-${GOOGLE_CLIENT_ID:-}}"
google_client_secret="${3:-${GOOGLE_CLIENT_SECRET:-}}"

if [[ -z "$env" ]]; then
  echo "Usage: $0 [env] [google-client-id] [google-client-secret]"
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

# Validate Google credentials
if [[ -z "$google_client_id" ]]; then
  echo "Google Client ID is required"
  echo "Pass as argument or set GOOGLE_CLIENT_ID environment variable"
  exit 1
fi

if [[ -z "$google_client_secret" ]]; then
  echo "Google Client Secret is required"
  echo "Pass as argument or set GOOGLE_CLIENT_SECRET environment variable"
  exit 1
fi

echo "Google Client ID: ${google_client_id:0:20}..."
echo ""

echo "Deploying infrastructure with AWS SAM..."
cd ../infra

# Ensure artifacts exist
if [ ! -f "../hello-backend/build/libs/hello-backend-0.1-lambda.zip" ]; then
  echo "Backend artifact not found. Run ./build-backend.sh first"
  exit 1
fi

# Validate template
echo "Validating SAM template..."
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

echo ""
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
    DomainName=${domain} \
    Environment=${env} \
    CertificateArn=${cert_arn} \
    GoogleClientId=${google_client_id} \
    GoogleClientSecret=${google_client_secret} || {
  echo "Deployment failed. Checking changeset details..."
  CHANGESET_NAME=$(aws cloudformation list-change-sets --stack-name "${app_stack}" --region "${APP_REGION}" --query "Summaries[0].ChangeSetName" --output text 2>&1)
  if [[ -n "$CHANGESET_NAME" && "$CHANGESET_NAME" != "None" ]]; then
    echo "Latest changeset: $CHANGESET_NAME"
    aws cloudformation describe-change-set --change-set-name "$CHANGESET_NAME" --stack-name "${app_stack}" --region "${APP_REGION}" --query "StatusReason" --output text
  fi
  exit 1
}

echo ""
echo "Infrastructure deployment complete!"

# Show Cognito outputs
echo ""
echo "Cognito Configuration:"
echo "========================="

user_pool_id=$(aws cloudformation describe-stacks \
  --region "${APP_REGION}" \
  --stack-name "${app_stack}" \
  --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" \
  --output text)

client_id=$(aws cloudformation describe-stacks \
  --region "${APP_REGION}" \
  --stack-name "${app_stack}" \
  --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" \
  --output text)

cognito_domain=$(aws cloudformation describe-stacks \
  --region "${APP_REGION}" \
  --stack-name "${app_stack}" \
  --query "Stacks[0].Outputs[?OutputKey=='CognitoDomain'].OutputValue" \
  --output text)

echo "User Pool ID:     ${user_pool_id}"
echo "Client ID:        ${client_id}"
echo "Cognito Domain:   ${cognito_domain}"
echo ""
echo "Add Google OAuth redirect URI in Google Cloud Console:"
echo "  ${cognito_domain}/oauth2/idpresponse"
echo ""
echo "Update hello-frontend/.env with:"
echo "  VITE_COGNITO_USER_POOL_ID=${user_pool_id}"
echo "  VITE_COGNITO_CLIENT_ID=${client_id}"
echo "  VITE_COGNITO_REGION=${APP_REGION}"
echo "  VITE_COGNITO_DOMAIN=${cognito_domain}"

echo ""
echo "Next steps:"
echo "   1. Note the CloudFrontDomain output from SAM"
echo "   2. Configure DNS: ${domain} CNAME → <CloudFrontDomain>"
echo "   3. Run: ./deploy-frontend.sh ${env}"
exit 0
