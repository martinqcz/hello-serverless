# Deployment Scripts

This directory contains automation scripts for building, deploying, and undeploying the Hello Serverless application.

## Prerequisites

- **AWS CLI** configured with credentials (`aws configure`)
- **AWS SAM CLI** installed
- **Docker** running (for GraalVM native builds)
- **Bun** installed (for frontend builds)

## Scripts Overview

| Script | Purpose | Parameters |
|--------|---------|------------|
| `build-backend.sh` | Build GraalVM native Lambda (ARM64) | None |
| `build-frontend.sh` | Build Vue 3 frontend with type checking | None |
| `deploy-cert.sh` | Deploy ACM certificate stack | `[env]` |
| `deploy-app.sh` | Deploy application infrastructure | `[env]` |
| `deploy-frontend.sh` | Upload frontend to S3 + invalidate CloudFront | `[env]` |
| `undeploy-cert.sh` | Delete certificate stack | `[env]` |
| `undeploy-app.sh` | Delete application stack | `[env]` |
| `undeploy-frontend.sh` | Empty S3 bucket (remove all files) | `[env]` |

**Environment Configuration**:

Domain names are configured in `env-config.sh`:
```bash
declare -A ENV_DOMAINS
ENV_DOMAINS[dev]="hello-dev.qapil.com"
ENV_DOMAINS[prod]="hello-app.qapil.com"
```

Valid environments: `dev`, `prod`

**Examples**:
```bash
# Deploy production environment
./deploy-cert.sh prod
./deploy-app.sh prod
./deploy-frontend.sh prod

# Deploy dev environment
./deploy-cert.sh dev
./deploy-app.sh dev
./deploy-frontend.sh dev
```

---

## Certificate Management (Automated)

The certificate is now **automatically created and managed** by CloudFormation through the `cert-stack.yaml` template. You don't need to manually create certificates via AWS CLI.

### Step 1: Deploy Certificate Stack

```bash
cd scripts

# Deploy certificate for production
./deploy-cert.sh prod

# OR deploy for dev environment
./deploy-cert.sh dev
```

The script will:
1. Create ACM certificate in `us-east-1` (required for CloudFront)
2. Output the certificate ARN
3. Display DNS validation records (CNAME) that need to be added

**Example output**:
```
CertificateArn: arn:aws:acm:us-east-1:123456789012:certificate/abc-123...

DNS validation record(s) to add (CNAME):
[
    {
        "Name": "_abc123.hello-dev.qapil.com.",
        "Type": "CNAME",
        "Value": "_xyz789.acm-validations.aws."
    }
]

Certificate Status
PENDING_VALIDATION
```

### Step 2: Add DNS Validation Record

Go to your DNS provider and create a **CNAME record**:

| Field | Value |
|-------|-------|
| **Name** | `_abc123.hello-dev.qapil.com` (from output) |
| **Type** | `CNAME` |
| **Value** | `_xyz789.acm-validations.aws` (from output) |
| **TTL** | `300` (5 minutes) |

**Important Notes**:
- Some DNS providers auto-append the domain, so you might only need `_abc123`
- Don't include trailing dots unless your DNS provider requires them
- This is a **different** CNAME than your application domain

### Step 3: Wait for Validation

ACM will automatically validate once DNS propagates (5-30 minutes).

**Check validation status**:
```bash
# The deploy-cert.sh script shows current status
# You can also check manually:
aws acm describe-certificate \
  --certificate-arn <CertificateArn> \
  --region us-east-1 \
  --query "Certificate.Status" \
  --output text

# Wait for output: "ISSUED"
```

**Monitor in real-time**:
```bash
watch -n 30 "aws acm describe-certificate \
  --certificate-arn <CertificateArn> \
  --region us-east-1 \
  --query Certificate.Status \
  --output text"

# Press Ctrl+C when status shows "ISSUED"
```

### Verification

Once certificate status is `ISSUED`, proceed to deploy the application stack.

### Troubleshooting Certificate Validation

#### Issue: "Status stuck on PENDING_VALIDATION"

**Causes**:
- DNS validation record not added correctly
- DNS not propagated yet
- Wrong DNS record type (must be CNAME, not TXT or A)

**Solutions**:
```bash
# 1. Verify DNS record exists
dig _abc123.hello-dev.qapil.com CNAME

# 2. Re-check validation records from CloudFormation
aws cloudformation describe-stacks \
  --stack-name hello-cert-dev \
  --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='CertificateArn'].OutputValue" \
  --output text

# 3. Wait longer (DNS can take up to 48 hours, usually <30 mins)

# 4. If >1 hour, delete and recreate certificate stack
./undeploy-cert.sh dev
./deploy-cert.sh dev
```

### Certificate Lifecycle

**Important**: The certificate is managed by the `cert-stack`:
- Created automatically during `deploy-cert.sh`
- Persists independently of the application stack
- **Deleted** when running `undeploy-cert.sh`
- Can be reused across multiple app deployments (dev/prod)

---

## Deployment Workflow

### Full Deployment (First Time)

#### 1. Build Application
```bash
cd scripts
./build-backend.sh     # ~5-10 minutes (GraalVM compilation)
./build-frontend.sh    # ~2 minutes
```

#### 2. Deploy Certificate Stack
```bash
cd scripts
./deploy-cert.sh prod  # ~1 minute
```

**Output will include**:
- Certificate ARN
- DNS validation CNAME record to add

**Action required**: Add the CNAME validation record to your DNS provider.

**Wait**: 5-30 minutes for certificate to become `ISSUED` status.

#### 3. Deploy Application Stack
```bash
cd scripts
./deploy-app.sh prod  # ~10-15 minutes (first deployment)
```

The script will:
- Verify certificate is in `ISSUED` status
- Deploy Lambda, API Gateway, DynamoDB, S3, CloudFront
- Output CloudFront domain name

**Save outputs from deployment**:
- `CloudFrontDomain` (e.g., `d1234567890.cloudfront.net`)
- `CloudFrontDistributionId`
- `ApiGatewayUrl`
- `FrontendBucketName`

#### 4. Deploy Frontend
```bash
cd scripts
./deploy-frontend.sh prod   # ~1 minute
```

This uploads the Vue app to S3 and invalidates CloudFront cache.

#### 5. Configure DNS
Create a CNAME record in your DNS provider for the **application domain**:

| Field | Value |
|-------|-------|
| **Name** | `hello-app.qapil.com` |
| **Type** | `CNAME` |
| **Value** | `<CloudFrontDomain from step 3>` (e.g., `d1234567890.cloudfront.net`) |
| **TTL** | `300` |

**Note**: This is separate from the certificate validation CNAME record.

### Quick Deployment (Subsequent Times)

If you've already deployed once and just need to update:

```bash
cd scripts

# Update backend code
./build-backend.sh
./deploy-app.sh prod

# Update frontend code
./build-frontend.sh
./deploy-frontend.sh prod
```

### Multi-Environment Deployment

Deploy to multiple environments (dev, prod):

```bash
cd scripts

# Build once
./build-backend.sh
./build-frontend.sh

# Deploy dev environment
./deploy-cert.sh dev
# (Wait for certificate validation)
./deploy-app.sh dev
./deploy-frontend.sh dev

# Deploy prod environment
./deploy-cert.sh prod
# (Wait for certificate validation)
./deploy-app.sh prod
./deploy-frontend.sh prod
```

Each environment gets its own:
- Certificate stack: `hello-cert-dev`, `hello-cert-prod`
- Application stack: `hello-app-dev`, `hello-app-prod`
- S3 bucket: `hello-frontend-dev-<AccountId>`, `hello-frontend-prod-<AccountId>`
- CloudFront distribution

---

## Undeploy Workflow

### Full Undeploy (Recommended Order)

To completely remove all resources for an environment:

```bash
cd scripts

# 1. Empty frontend bucket (optional but recommended)
./undeploy-frontend.sh prod

# 2. Delete application stack (Lambda, API Gateway, DynamoDB, S3, CloudFront)
./undeploy-app.sh prod

# 3. Delete certificate stack (optional - can be reused)
./undeploy-cert.sh prod
```

**Estimated time**:
- Frontend: 1-2 minutes (empties S3 bucket)
- Application stack: 5-10 minutes (CloudFront deletion continues in background)
- Certificate stack: 1-2 minutes

### Quick Undeploy (Application Only)

To remove the application but keep the certificate for redeployment:

```bash
cd scripts
./undeploy-app.sh prod
```

This deletes:
- Lambda function: `hello-backend-prod`
- API Gateway HTTP API
- DynamoDB table: `hello`
- S3 bucket: `hello-frontend-prod-<AccountId>` (including all files)
- CloudFront distribution
- IAM roles and policies

**Certificate stack remains** for future redeployment.

### Partial Undeploy (Frontend Only)

To remove frontend files but keep infrastructure:

```bash
cd scripts
./undeploy-frontend.sh prod
```

This only empties the S3 bucket without deleting any AWS infrastructure.

---

## Important Undeploy Notes

### 1. No Confirmation Prompts
All undeploy scripts run with `--no-prompts` flag for automation. They will:
- Check if stack/resources exist
- Delete without confirmation if found
- Exit gracefully if already deleted

**Use with caution** - ensure you're targeting the correct environment.

### 2. What Gets Deleted

By `undeploy-app.sh`:
- ✅ Lambda function: `hello-backend-{env}`
- ✅ API Gateway HTTP API
- ✅ DynamoDB table: `hello`
- ✅ S3 bucket: `hello-frontend-{env}-<AccountId>` (including all files)
- ✅ CloudFront distribution
- ✅ IAM execution roles
- ✅ CloudWatch log groups (after retention period)

By `undeploy-cert.sh`:
- ✅ ACM certificate for the domain
- ⚠️ **DNS validation CNAME records persist** (managed externally)

Never deleted automatically:
- ⚠️ DNS records for application domain (managed externally)
- ⚠️ Build artifacts (`hello-backend/build/`, `hello-frontend/dist/`)

### 3. CloudFront Deletion Time
CloudFront distributions take **15-60 minutes** to fully delete after the stack deletion completes. This is normal AWS behavior. The distribution will be marked as "Disabled" immediately but takes time to propagate globally.

### 4. S3 Versioning
The bucket has versioning enabled. The `undeploy-frontend.sh` and `undeploy-app.sh` scripts automatically:
- Delete all object versions
- Delete all delete markers
- Empty the bucket completely before CloudFormation deletion

### 5. Stack Independence
The certificate stack and application stack are independent:
- You can delete the application stack while keeping the certificate
- Redeploying the application reuses the existing certificate
- Delete certificate stack only when you no longer need it for any environment

### 6. Cost After Undeploy
Once undeployed, you will **not be charged** for any resources except:
- ACM certificate (always free, even if kept)
- Any CloudWatch logs within retention period (usually free tier)

---

## Manual Cleanup (If Needed)

### Delete Certificate Stack (Alternative Method)
If the undeploy script fails:

```bash
aws cloudformation delete-stack \
  --stack-name hello-cert-prod \
  --region us-east-1
```

**Note**: Certificate must not be in use by any CloudFront distribution. Wait for `undeploy-app.sh` to complete first.

### Delete DNS Records
Remove CNAME records from your DNS provider:

1. **Certificate validation record** (if no longer needed):
   - Name: `_abc123.hello-app.qapil.com`
   - Type: `CNAME`

2. **Application domain record**:
   - Name: `hello-app.qapil.com`
   - Type: `CNAME`

### Verify Cleanup
Check that all resources are deleted for an environment:

```bash
# Check CloudFormation stacks
aws cloudformation describe-stacks \
  --stack-name hello-app-prod \
  --region us-east-1
# Should return: "Stack does not exist"

aws cloudformation describe-stacks \
  --stack-name hello-cert-prod \
  --region us-east-1
# Should return: "Stack does not exist"

# Check S3 buckets
aws s3 ls | grep hello-frontend
# Should return: empty (or only other environments)

# Check Lambda functions
aws lambda list-functions --region us-east-1 --query "Functions[?FunctionName=='hello-backend-prod']"
# Should return: empty list

# Check CloudFront distributions
aws cloudfront list-distributions \
  --query "DistributionList.Items[?Comment=='Hello Serverless - prod'].{Id:Id,Status:Status}"
# Should return: empty or Status: "InProgress" (still deleting)
```

---

## Troubleshooting Undeploy

### Issue: "Stack does not exist"
**Solution**: Stack is already deleted. No action needed. Script exits gracefully.

### Issue: "An error occurred (ValidationError) when calling the DescribeStacks operation"
**Solution**: Stack was manually deleted. Clean up S3 bucket manually if needed:
```bash
# Find bucket name for the environment
aws s3 ls | grep hello-frontend-prod

# Empty and delete bucket (replace with actual bucket name)
aws s3 rm s3://hello-frontend-prod-<AccountId> --recursive
aws s3 rb s3://hello-frontend-prod-<AccountId> --force
```

### Issue: "Stack cannot be deleted while resources are in use"
**Cause**: CloudFront distribution might still be associated with the S3 bucket.

**Solution**: Run `undeploy-frontend.sh` first to empty the bucket:
```bash
cd scripts
./undeploy-frontend.sh prod

# Wait 2-3 minutes, then retry
./undeploy-app.sh prod
```

### Issue: "Certificate is in use by CloudFront distribution"
**Cause**: Application stack still exists and uses the certificate.

**Solution**: Delete application stack first, then certificate:
```bash
cd scripts
./undeploy-app.sh prod
# Wait for CloudFront deletion (5-10 minutes)
./undeploy-cert.sh prod
```

### Issue: "Access Denied" when deleting S3 objects
**Cause**: IAM permissions issue or bucket policy conflict.

**Solution**: Use S3 Console to empty bucket manually, then retry:
```bash
cd scripts
./undeploy-app.sh prod
```

### Issue: "The specified bucket does not exist"
**Solution**: Bucket already deleted. Skip to stack deletion:
```bash
cd infra
sam delete --stack-name hello-app-prod --region us-east-1 --no-prompts
```

---

## Re-Deployment After Undeploy

### If Certificate Stack Was Kept
If you only deleted the application stack but kept the certificate:

```bash
cd scripts

# 1. Build (if code changed)
./build-backend.sh
./build-frontend.sh

# 2. Deploy application (certificate already exists and is ISSUED)
./deploy-app.sh prod

# 3. Deploy frontend
./deploy-frontend.sh prod
```

### If Certificate Stack Was Also Deleted
If you deleted both stacks:

```bash
cd scripts

# 1. Build (if code changed)
./build-backend.sh
./build-frontend.sh

# 2. Deploy certificate
./deploy-cert.sh prod
# (Wait for certificate validation - same DNS record as before)

# 3. Deploy application
./deploy-app.sh prod

# 4. Deploy frontend
./deploy-frontend.sh prod
```

**Note**:
- If using the same domain, DNS validation record is the same (if still in DNS, validation is instant)
- Application domain DNS record (CNAME to CloudFront) doesn't change if using same domain
- Build artifacts in `hello-backend/build/` and `hello-frontend/dist/` are reused if unchanged

---

## Cost Savings

Undeploying when not actively using the application saves costs:

| Scenario | Monthly Cost |
|----------|--------------|
| **Always deployed** | $0.00 (within free tier for low traffic) |
| **Undeployed** | $0.00 (no resources running) |
| **Deploy only when needed** | $0.00 (best practice for test/demo apps) |

**Recommendation**: For test/demo applications, undeploy when not in use to:
- Avoid potential free tier overages
- Keep AWS account clean
- Practice infrastructure-as-code principles

---

## Quick Reference

### Deploy Everything (First Time)
```bash
cd scripts

# Build
./build-backend.sh && ./build-frontend.sh

# Deploy
./deploy-cert.sh prod
# (Add DNS validation CNAME, wait for ISSUED status)

./deploy-app.sh prod
./deploy-frontend.sh prod
```

### Update Backend Only
```bash
cd scripts
./build-backend.sh
./deploy-app.sh prod
```

### Update Frontend Only
```bash
cd scripts
./build-frontend.sh
./deploy-frontend.sh prod
```

### Undeploy Everything
```bash
cd scripts
./undeploy-frontend.sh prod  # Optional
./undeploy-app.sh prod
./undeploy-cert.sh prod      # Optional (can keep for redeployment)
```

### Undeploy Application Only (Keep Certificate)
```bash
cd scripts
./undeploy-app.sh prod
```

### Deploy Multiple Environments
```bash
cd scripts

# Build once
./build-backend.sh && ./build-frontend.sh

# Deploy dev
./deploy-cert.sh dev
./deploy-app.sh dev
./deploy-frontend.sh dev

# Deploy prod
./deploy-cert.sh prod
./deploy-app.sh prod
./deploy-frontend.sh prod
```

### Emergency Cleanup (Force Delete)
```bash
# Empty bucket manually (replace env and account ID)
aws s3 rm s3://hello-frontend-prod-$(aws sts get-caller-identity --query Account --output text) --recursive

# Delete stacks (no prompts)
cd infra
sam delete --stack-name hello-app-prod --region us-east-1 --no-prompts
sam delete --stack-name hello-cert-prod --region us-east-1 --no-prompts
```

---

## Support

For issues with deployment or undeploy scripts:
1. Check AWS CloudFormation Console → Stack Events tab
   - Certificate stack: `hello-cert-{env}`
   - Application stack: `hello-app-{env}`
2. Review script output for error messages
3. Verify AWS CLI credentials: `aws sts get-caller-identity`
4. Check prerequisites are installed and configured

For infrastructure questions, refer to:
- Certificate template: `infra/cert-stack.yaml`
- Application template: `infra/app-stack.yaml`
- Project documentation: `CLAUDE.md` (root directory)

### Common Stack Names by Environment

| Environment | Certificate Stack | Application Stack | Domain (from env-config.sh) |
|-------------|------------------|-------------------|---------------------------|
| **dev** | `hello-cert-dev` | `hello-app-dev` | `hello-dev.qapil.com` |
| **prod** | `hello-cert-prod` | `hello-app-prod` | `hello-app.qapil.com` |

To add more environments (e.g., staging), edit `env-config.sh` and add the domain mapping.
