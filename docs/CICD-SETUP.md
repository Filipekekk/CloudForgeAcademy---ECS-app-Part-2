# CI/CD Setup Guide

## Prerequisites

- AWS Account with admin access
- GitHub account
- Terraform installed locally

## Step 1: Create Backend Resources

```bash
# S3 bucket
aws s3api create-bucket \
  --bucket your-terraform-state-bucket \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# DynamoDB table
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## Step 2: Create OIDC Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## Step 3: Deploy IAM Roles

```bash
cd iam-roles
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

## Step 4: Configure GitHub

**Secrets** (Settings → Secrets and variables → Actions):
- `AWS_TERRAFORM_PLAN_ROLE_ARN` - From step 3
- `AWS_TERRAFORM_APPLY_ROLE_ARN` - From step 3
- `ECR_REPOSITORY_NAME` - `static-website-dev-app`

**Environments**:
1. Create `production` environment
2. Add required reviewers
3. Restrict to `main` branch

## Step 5: Deploy

```bash
git push origin main
```

Pipeline will run automatically. Approve Apply stage when ready.

## Troubleshooting

### OIDC Error
Check trust policy includes your repository:
```bash
aws iam get-role --role-name your-plan-role
```

### State Lock Error
```bash
terraform force-unlock LOCK_ID
```