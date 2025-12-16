# ECS Fargate Application with Terraform - Part 3

Complete Infrastructure as Code solution for deploying a containerized Flask application on AWS ECS Fargate with Auto-Scaling, CI/CD pipeline, and OIDC authentication.

## Features

- ✅ **Auto-Scaling**: ECS Service scales between 1-3 tasks based on CPU utilization
- ✅ **CI/CD Pipeline**: Automated deployment via GitHub Actions
- ✅ **OIDC Authentication**: Secure AWS access without long-lived credentials
- ✅ **Centralized Logging**: CloudWatch Logs with 14-day retention
- ✅ **High Availability**: Multi-AZ deployment with ALB
- ✅ **Security**: Tasks in private subnets, least privilege IAM roles
- ✅ **State Management**: Remote state with locking (S3 + DynamoDB)

## Architecture

```
Internet → ALB (Public Subnets) → ECS Fargate (Private Subnets)
                                      ↓
                               Auto-Scaling (1-3 tasks)
                                      ↓
                            CloudWatch Logs (14 days)
```

## Prerequisites

- AWS Account with admin permissions
- Terraform >= 1.0
- AWS CLI configured
- GitHub account
- Docker installed

## Repository Structure

```
part3/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── versions.tf
├── backend.tf
├── locals.tf
├── .gitignore
├── .tflint.hcl
├── Makefile
│
├── app/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── .github/
│   └── workflows/
│       └── terraform.yml
│
├── iam-roles/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
│
├── scripts/
│   ├── setup-oidc.sh
│   ├── test-autoscaling.sh
│   ├── monitor-deployment.sh
│   └── generate-load.sh
│
├── docs/
│   ├── CICD-SETUP.md
│   ├── AUTOSCALING-GUIDE.md
│   └── DEPLOYMENT-CHECKLIST.md
│
└── modules/
    ├── networking/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── versions.tf
    │
    ├── ecr/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── versions.tf
    │
    ├── ecs/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── versions.tf
    │   ├── iam.tf
    │   └── autoscaling.tf
    │
    ├── alb/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── versions.tf
    │
    └── cloudwatch/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── versions.tf
```

## Quick Start

### 1. Prepare Backend

```bash
# Create S3 bucket
aws s3api create-bucket \
  --bucket your-terraform-state-bucket \
  --region eu-central-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1
```

### 2. Setup OIDC IAM Roles

```bash
cd iam-roles

# Edit terraform.tfvars with your values
cat > terraform.tfvars <<EOF
github_organization    = "your-username"
github_repository      = "your-repo"
terraform_state_bucket = "your-terraform-state-bucket"
terraform_lock_table   = "terraform-state-lock"
EOF

terraform init
terraform apply

# Save the role ARNs
terraform output terraform_plan_role_arn
terraform output terraform_apply_role_arn
```

### 3. Configure GitHub Secrets

Go to: **Settings → Secrets and variables → Actions**

Add these secrets:
- `AWS_TERRAFORM_PLAN_ROLE_ARN` - From step 2
- `AWS_TERRAFORM_APPLY_ROLE_ARN` - From step 2
- `ECR_REPOSITORY_NAME` - `static-website-dev-app`

### 4. Deploy Infrastructure

```bash
cd part3

# Copy and edit configuration
cp terraform.tfvars.example terraform.tfvars

# Initialize
terraform init

# Deploy
terraform plan
terraform apply
```

### 5. Push to GitHub

```bash
git add .
git commit -m "Initial deployment"
git push origin main

# This triggers:
# ✅ Init & Validate (automatic)
# ✅ Plan (automatic)
# ✅ Build & Push Docker (automatic)
# ⏸️ Apply (manual approval required)
```

### 6. Approve Deployment

1. Go to GitHub Actions
2. Click on the workflow
3. Review and approve deployment

### 7. Test Application

```bash
ALB_URL=$(terraform output -raw alb_url)

# Test main endpoint
curl $ALB_URL

# Test health check
curl $ALB_URL/health
```

## Auto-Scaling

**Scale Out**: CPU > 50% → Add task (max 3)  
**Scale In**: CPU < 25% for 5 minutes → Remove task (min 1)

### Test Auto-Scaling

```bash
cd scripts
./test-autoscaling.sh
```

## Monitoring

### CloudWatch Logs
```bash
aws logs tail /ecs/static-website-dev-app --follow
```

### ECS Service Status
```bash
aws ecs describe-services \
  --cluster static-website-dev-cluster \
  --services static-website-dev-service
```

### View Metrics
```bash
terraform output cloudwatch_logs_url
terraform output ecs_service_url
```

## CI/CD Pipeline

**Stages**:
1. **Init & Validate** - Format, validate, TFLint (automatic)
2. **Plan** - Generate terraform plan (automatic)
3. **Build & Push** - Build Docker image, push to ECR (automatic)
4. **Apply** - Deploy infrastructure (manual approval)

**Security**:
- Plan uses read-only IAM role
- Apply uses full-access IAM role
- No long-lived credentials
- State locking prevents concurrent runs

## Cleanup

```bash
terraform destroy
```

## Documentation

- [CI/CD Setup Guide](docs/CICD-SETUP.md)
- [Auto-Scaling Guide](docs/AUTOSCALING-GUIDE.md)
- [Deployment Checklist](docs/DEPLOYMENT-CHECKLIST.md)

## Troubleshooting

### ECS tasks not starting
```bash
aws ecs describe-services \
  --cluster static-website-dev-cluster \
  --services static-website-dev-service \
  --query 'services[0].events[0:5]'
```

### Health check failing
Check security groups allow ALB → ECS traffic on port 8080

### Pipeline fails
Check IAM role ARNs are correct in GitHub Secrets

## Cost Estimate

**Monthly costs (us-east-1)**:
- ECS Fargate (1 task avg): ~$15
- NAT Gateway: ~$32
- ALB: ~$16
- CloudWatch Logs: ~$0.50
- Total: **~$64/month**

## License

This project is part of a CloudForge Academy course and is confidential.
