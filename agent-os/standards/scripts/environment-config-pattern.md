# Environment Config Pattern

Centralized environment configuration in `env-config.sh`.

```bash
# env-config.sh
declare -A ENV_DOMAINS
ENV_DOMAINS[dev]="hello-dev.qapil.com"
ENV_DOMAINS[prod]="hello-app.qapil.com"

STACK_BASE_NAME="hello"
CERT_REGION="us-east-1"
APP_REGION="us-east-1"

get_domain() {
  local env=$1
  echo "${ENV_DOMAINS[$env]}"
}

validate_env() {
  local env=$1
  if [[ -z "${ENV_DOMAINS[$env]}" ]]; then
    echo "❌ Invalid environment: $env"
    return 1
  fi
  return 0
}
```

**Why:**
- Single source of truth for environment definitions
- Adding new environment only requires editing this file
- All scripts stay consistent automatically

**Usage in scripts:**
```bash
source ./env-config.sh

if ! validate_env "$env"; then exit 1; fi
domain=$(get_domain "$env")
```
