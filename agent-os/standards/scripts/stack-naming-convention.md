# Stack Naming Convention

CloudFormation stacks follow pattern: `{base}-{resource}-{env}`

| Stack | Purpose |
|-------|--------|
| `hello-cert-dev` | ACM certificate for dev |
| `hello-cert-prod` | ACM certificate for prod |
| `hello-app-dev` | Lambda, API Gateway, DynamoDB, CloudFront for dev |
| `hello-app-prod` | Lambda, API Gateway, DynamoDB, CloudFront for prod |

**Why:**
- All environments in single AWS account—names differentiate them
- Pattern is predictable: scripts can construct stack names programmatically

**Pattern:**
```bash
STACK_BASE_NAME="hello"

cert_stack="${STACK_BASE_NAME}-cert-${env}"   # hello-cert-prod
app_stack="${STACK_BASE_NAME}-app-${env}"     # hello-app-prod
```

- Base name defined in `env-config.sh`
- Resource type: `cert`, `app`, etc.
- Environment suffix: `dev`, `prod`
