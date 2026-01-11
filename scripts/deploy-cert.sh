#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./deploy-cert.sh [env]
#
# Examples:
#   ./deploy-cert.sh dev
#   ./deploy-cert.sh prod
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

echo "🚀 Deploying domain certificate with AWS SAM..."
cd ../infra

# Validate template
echo "🔍 Validating SAM template..."
sam validate --template-file cert-stack.yaml

cert_stack="${STACK_BASE_NAME}-cert-${env}"

echo "Deploying cert stack to ${CERT_REGION}: ${cert_stack}"
sam deploy \
  --template-file cert-stack.yaml \
  --stack-name "${cert_stack}" \
  --region "${CERT_REGION}" \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset \
  --parameter-overrides DomainName="${domain}"

cert_arn="$(
  aws cloudformation describe-stacks \
    --region "${CERT_REGION}" \
    --stack-name "${cert_stack}" \
    --query "Stacks[0].Outputs[?OutputKey=='CertificateArn'].OutputValue | [0]" \
    --output text
)"

echo ""
echo "CertificateArn: ${cert_arn}"
echo ""
echo "DNS validation record(s) to add (CNAME):"
aws acm describe-certificate \
  --region "${CERT_REGION}" \
  --certificate-arn "${cert_arn}" \
  --query "Certificate.DomainValidationOptions[*].ResourceRecord" \
  --output json

echo ""
echo "Certificate Status"
aws acm describe-certificate \
  --region "${CERT_REGION}" \
  --certificate-arn "${cert_arn}" \
  --query "Certificate.Status" \
  --output text

echo ""
echo "After you add the CNAME record(s) in your DNS provider and the cert becomes ISSUED,"
echo "run the app deploy step:"
echo "  ./deploy-app.sh ${env}"
exit 0
