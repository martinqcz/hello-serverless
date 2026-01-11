#!/usr/bin/env bash
# Environment configuration for deployments
# Maps environment names to their corresponding domain names

# Domain configuration per environment
declare -A ENV_DOMAINS
ENV_DOMAINS[dev]="hello-dev.qapil.com"
ENV_DOMAINS[prod]="hello-app.qapil.com"

# Base stack configuration
STACK_BASE_NAME="hello"
CERT_REGION="us-east-1"
APP_REGION="us-east-1"

# Function to get domain for environment
get_domain() {
  local env=$1
  echo "${ENV_DOMAINS[$env]}"
}

# Function to validate environment
validate_env() {
  local env=$1
  if [[ -z "${ENV_DOMAINS[$env]}" ]]; then
    echo "❌ Invalid environment: $env"
    echo "Valid environments: ${!ENV_DOMAINS[@]}"
    return 1
  fi
  return 0
}
