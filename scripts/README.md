# Deployment Scripts

This directory contains automation scripts for building, deploying, and undeploying the Hello Serverless application.

## Prerequisites

- **AWS CLI** configured with credentials (`aws configure`)
- **AWS SAM CLI** installed
- **Docker** running (for GraalVM native builds)
- **Bun** installed (for frontend builds)

## Scripts Overview

| Script | Purpose | Run From |
|--------|---------|----------|
| `build-backend.sh` | Build GraalVM native Lambda (ARM64) | `scripts/` |
| `build-frontend.sh` | Build Vue 3 frontend with type checking | `scripts/` |
| `deploy-infrastructure.sh` | Deploy AWS infrastructure (SAM stack) | `scripts/` |
| `deploy-frontend.sh` | Upload frontend to S3 + invalidate CloudFront | `scripts/` |
| `undeploy-frontend.sh` | Empty S3 bucket (remove all files) | `scripts/` |
| `undeploy-infrastructure.sh` | Delete all AWS resources | `scripts/` |

---

## Creating ACM Certificate (First-Time Setup)

Before deploying infrastructure, you need an SSL certificate for `hello.qapil.com`.

### Step 1: Request Certificate

**Important**: The certificate MUST be in `us-east-1` region (required for CloudFront).

```bash
# Request certificate with DNS validation
aws acm request-certificate \
  --domain-name hello.qapil.com \
  --validation-method DNS \
  --region us-east-1 \
  --tags Key=Application,Value=hello-serverless Key=Environment,Value=prod

# Note the CertificateArn from output
# Example: arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
```

**Save the `CertificateArn`** - you'll need it for deployment configuration.

### Step 2: Get DNS Validation Records

```bash
# Replace <CertificateArn> with your actual ARN
aws acm describe-certificate \
  --certificate-arn <CertificateArn> \
  --region us-east-1 \
  --query "Certificate.DomainValidationOptions[0].ResourceRecord" \
  --output table

# Output example:
# ----------------------------------------
# |         ResourceRecord                |
# +--------------------------------------+
# |  Name   | _abc123.hello.qapil.com.  |
# |  Type   | CNAME                      |
# |  Value  | _xyz789.acm-validations... |
# +--------------------------------------+
```

### Step 3: Add DNS Validation Record

Go to your DNS provider and create a **CNAME record**:

| Field | Value |
|-------|-------|
| **Name** | `_abc123.hello.qapil.com` (from ResourceRecord.Name) |
| **Type** | `CNAME` |
| **Value** | `_xyz789.acm-validations...` (from ResourceRecord.Value) |
| **TTL** | `300` (5 minutes) |

**Important Notes**:
- Some DNS providers auto-append the domain, so you might only need `_abc123`
- Don't include trailing dots unless your DNS provider requires them
- This is a **different** CNAME than your application domain

### Step 4: Wait for Validation

ACM will automatically validate once DNS propagates (5-30 minutes).

**Check validation status**:
```bash
aws acm describe-certificate \
  --certificate-arn <CertificateArn> \
  --region us-east-1 \
  --query "Certificate.Status" \
  --output text

# Wait for output: "ISSUED"
# Status will be "PENDING_VALIDATION" until DNS propagates
```

**Monitor in real-time**:
```bash
# Check every 30 seconds until issued
watch -n 30 "aws acm describe-certificate \
  --certificate-arn <CertificateArn> \
  --region us-east-1 \
  --query Certificate.Status \
  --output text"

# Press Ctrl+C when status shows "ISSUED"
```

### Step 5: Update Deployment Configuration

Edit `infra/samconfig.toml` and replace the placeholder:

```toml
parameter_overrides = [
    "DomainName=hello.qapil.com",
    "CertificateArn=<REPLACE_WITH_ACM_CERT_ARN>",  # Replace this line
    "Environment=prod"
]
```

**With your certificate ARN**:
```toml
parameter_overrides = [
    "DomainName=hello.qapil.com",
    "CertificateArn=arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012",
    "Environment=prod"
]
```

### Verification

Confirm certificate is ready:
```bash
aws acm describe-certificate \
  --certificate-arn <CertificateArn> \
  --region us-east-1 \
  --query "Certificate.[DomainName,Status,Type]" \
  --output table

# Expected output:
# ------------------------------
# |  hello.qapil.com          |
# |  ISSUED                   |
# |  AMAZON_ISSUED            |
# ------------------------------
```

### Troubleshooting Certificate Creation

#### Issue: "Status stuck on PENDING_VALIDATION"

**Causes**:
- DNS validation record not added correctly
- DNS not propagated yet
- Wrong DNS record type (must be CNAME, not TXT or A)

**Solutions**:
```bash
# 1. Verify DNS record exists
dig _abc123.hello.qapil.com CNAME

# 2. Check validation record details again
aws acm describe-certificate \
  --certificate-arn <CertificateArn> \
  --region us-east-1 \
  --query "Certificate.DomainValidationOptions[0].ResourceRecord"

# 3. Wait longer (DNS can take up to 48 hours, usually <30 mins)

# 4. If >1 hour, delete and recreate certificate
aws acm delete-certificate --certificate-arn <CertificateArn> --region us-east-1
# Then start over with Step 1
```

#### Issue: "ValidationException: Certificate ARN is not valid"

**Cause**: Certificate is in wrong region or doesn't exist.

**Solution**: Certificate MUST be in `us-east-1` (CloudFront requirement). Recreate in correct region.

#### Issue: "DNS validation record conflicts with existing record"

**Solution**: If you have an existing CNAME at the validation subdomain, use email validation instead:
```bash
aws acm request-certificate \
  --domain-name hello.qapil.com \
  --validation-method EMAIL \
  --region us-east-1
```

### Certificate Reuse

**Good news**: Once created, the certificate can be reused indefinitely:
- Persists after undeploy (not deleted by undeploy scripts)
- Can be used for multiple deployments
- No need to recreate for re-deployment
- Valid for 13 months, auto-renewed by AWS

---

## Deployment Workflow

### 1. Build Application
```bash
cd scripts
./build-backend.sh     # ~5-10 minutes (GraalVM compilation)
./build-frontend.sh    # ~2 minutes
```

### 2. Deploy Infrastructure
```bash
cd scripts
./deploy-infrastructure.sh  # ~10-15 minutes (first deployment)
```

**Save outputs from deployment**:
- `CloudFrontDomain` (e.g., `d1234567890.cloudfront.net`)
- `CloudFrontDistributionId`
- `ApiGatewayUrl`
- `FrontendBucketName`

### 3. Deploy Frontend
```bash
cd scripts
./deploy-frontend.sh   # ~1 minute
```

### 4. Configure DNS
Create a CNAME record in your DNS provider:
- **Name**: `hello.qapil.com`
- **Type**: `CNAME`
- **Value**: `<CloudFrontDomain from step 2>`

---

## Undeploy Workflow

### Quick Undeploy (Full Cleanup)

```bash
cd scripts
./undeploy-infrastructure.sh
```

This will:
1. Empty the S3 bucket (delete all files and versions)
2. Prompt for confirmation (type `yes` to proceed)
3. Delete the CloudFormation stack including:
   - Lambda function
   - API Gateway HTTP API
   - DynamoDB table
   - S3 bucket
   - CloudFront distribution
   - IAM roles and policies

**Estimated time**: 2-5 minutes (CloudFront deletion continues in background)

### Partial Undeploy (Frontend Only)

If you want to keep infrastructure but remove frontend files:

```bash
cd scripts
./undeploy-frontend.sh
```

This only empties the S3 bucket without deleting AWS infrastructure.

---

## Important Undeploy Notes

### 1. Safety Confirmation
The `undeploy-infrastructure.sh` script will prompt:
```
Are you sure you want to continue? (yes/no):
```
Type **`yes`** (not `y` or `Yes`) to proceed.

### 2. What Gets Deleted

✅ **Automatically deleted**:
- Lambda function: `hello-backend-prod`
- API Gateway HTTP API
- DynamoDB table: `hello`
- S3 bucket: `hello-frontend-<AccountId>` (including all files)
- CloudFront distribution
- IAM execution roles
- CloudWatch log groups

⚠️ **NOT automatically deleted**:
- ACM SSL certificate for `hello.qapil.com`
- DNS records (managed externally)

### 3. CloudFront Deletion Time
CloudFront distributions take **15-60 minutes** to fully delete after the stack deletion completes. This is normal AWS behavior. The distribution will be marked as "Disabled" immediately but takes time to propagate globally.

### 4. S3 Versioning
The bucket has versioning enabled. The undeploy script automatically:
- Deletes all object versions
- Deletes all delete markers
- Empties the bucket completely before CloudFormation deletion

### 5. Cost After Undeploy
Once undeployed, you will **not be charged** for any resources except:
- ACM certificate (always free)
- Any CloudWatch logs older than retention period (usually free tier)

---

## Manual Cleanup (If Needed)

### Delete ACM Certificate
If you no longer need the SSL certificate:

```bash
# 1. Get certificate ARN (from infra/samconfig.toml or AWS Console)
CERT_ARN="arn:aws:acm:us-east-1:123456789012:certificate/..."

# 2. Delete certificate
aws acm delete-certificate \
  --certificate-arn "$CERT_ARN" \
  --region us-east-1
```

**Note**: You can only delete certificates that are not in use. Wait for CloudFront deletion to complete first.

### Delete DNS Records
Remove the CNAME record from your DNS provider:
- **Name**: `hello.qapil.com`
- **Type**: `CNAME`

### Verify Cleanup
Check that all resources are deleted:

```bash
# Check CloudFormation stack
aws cloudformation describe-stacks \
  --stack-name hello-serverless \
  --region us-east-1
# Should return: "Stack does not exist"

# Check S3 bucket
aws s3 ls | grep hello-frontend
# Should return: empty

# Check Lambda functions
aws lambda list-functions --region us-east-1 | grep hello-backend
# Should return: empty

# Check CloudFront distributions
aws cloudfront list-distributions \
  --query "DistributionList.Items[?Comment=='Hello Serverless - prod'].{Id:Id,Status:Status}"
# Should return: empty or Status: "Deployed" (still deleting)
```

---

## Troubleshooting Undeploy

### Issue: "Stack does not exist"
**Solution**: Stack is already deleted. No action needed.

### Issue: "An error occurred (ValidationError) when calling the DescribeStacks operation"
**Solution**: Stack was manually deleted. Clean up S3 bucket manually:
```bash
# Find bucket name (should be hello-frontend-<AccountId>)
aws s3 ls | grep hello-frontend

# Empty and delete bucket
aws s3 rm s3://hello-frontend-<AccountId> --recursive
aws s3 rb s3://hello-frontend-<AccountId> --force
```

### Issue: "Stack cannot be deleted while resources are in use"
**Cause**: CloudFront distribution might still be associated with the S3 bucket.

**Solution**: Wait 5 minutes and retry. If still failing, disable CloudFront distribution manually:
```bash
# Get distribution ID
DIST_ID=$(aws cloudformation describe-stacks \
  --stack-name hello-serverless \
  --region us-east-1 \
  --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue" \
  --output text)

# Get distribution config
aws cloudfront get-distribution-config --id "$DIST_ID" > dist-config.json

# Edit dist-config.json: set "Enabled": false
# Then update distribution (this is complex, easier to use Console)
```

### Issue: "Access Denied" when deleting S3 objects
**Cause**: IAM permissions issue or bucket policy conflict.

**Solution**: Use S3 Console to empty bucket manually, then retry undeploy script.

### Issue: "The specified bucket does not exist"
**Solution**: Bucket already deleted. Run undeploy-infrastructure.sh directly:
```bash
cd scripts
# Skip to infrastructure deletion
cd ../infra
sam delete --stack-name hello-serverless --region us-east-1 --no-prompts
```

---

## Re-Deployment After Undeploy

To deploy again after undeploying:

```bash
cd scripts

# 1. Build (if code changed)
./build-backend.sh
./build-frontend.sh

# 2. Deploy infrastructure
./deploy-infrastructure.sh

# 3. Deploy frontend
./deploy-frontend.sh
```

**Note**:
- ACM certificate persists (can reuse same certificate ARN)
- DNS records persist (no changes needed if using same domain)
- Build artifacts in `hello-backend/build/` and `hello-frontend/dist/` are reused

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

### Deploy Everything
```bash
cd scripts
./build-backend.sh && ./build-frontend.sh && \
./deploy-infrastructure.sh && ./deploy-frontend.sh
```

### Update Backend Only
```bash
cd scripts
./build-backend.sh
cd ../infra && sam deploy
```

### Update Frontend Only
```bash
cd scripts
./build-frontend.sh
./deploy-frontend.sh
```

### Undeploy Everything
```bash
cd scripts
./undeploy-infrastructure.sh
```

### Emergency Cleanup (Force Delete)
```bash
# Empty bucket
aws s3 rm s3://hello-frontend-$(aws sts get-caller-identity --query Account --output text) --recursive

# Delete stack (no prompts)
cd infra
sam delete --stack-name hello-serverless --region us-east-1 --no-prompts
```

---

## Support

For issues with deployment or undeploy scripts:
1. Check AWS CloudFormation Console → `hello-serverless` stack → Events tab
2. Review script output for error messages
3. Verify AWS CLI credentials: `aws sts get-caller-identity`
4. Check prerequisites are installed and configured

For infrastructure questions, refer to:
- Main deployment plan: `~/.claude/plans/iterative-stirring-engelbart.md`
- SAM template: `infra/template.yaml`
- Project documentation: `CLAUDE.md`
