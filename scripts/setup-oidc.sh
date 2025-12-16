#!/bin/bash
set -e

echo "🔐 Setting up GitHub OIDC for AWS"

# Variables
GITHUB_ORG="${1:-your-github-username}"
GITHUB_REPO="${2:-your-repo-name}"
AWS_REGION="${3:-us-east-1}"

echo "GitHub Org/User: $GITHUB_ORG"
echo "GitHub Repo: $GITHUB_REPO"
echo "AWS Region: $AWS_REGION"

# Check if OIDC provider exists
echo "Checking if GitHub OIDC provider exists..."
PROVIDER_ARN=$(aws iam list-open-id-connect-providers \
  --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" \
  --output text)

if [ -z "$PROVIDER_ARN" ]; then
  echo "Creating GitHub OIDC provider..."
  aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
  
  PROVIDER_ARN=$(aws iam list-open-id-connect-providers \
    --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" \
    --output text)
  
  echo "✅ Created OIDC provider: $PROVIDER_ARN"
else
  echo "✅ OIDC provider already exists: $PROVIDER_ARN"
fi

# Deploy IAM roles
echo "Deploying IAM roles..."
cd iam-roles

cat > terraform.tfvars <<EOF
github_organization    = "$GITHUB_ORG"
github_repository      = "$GITHUB_REPO"
terraform_state_bucket = "your-terraform-state-bucket"
terraform_lock_table   = "terraform-state-lock"
aws_region             = "$AWS_REGION"
EOF

terraform init
terraform apply -auto-approve

# Get role ARNs
PLAN_ROLE_ARN=$(terraform output -raw terraform_plan_role_arn)
APPLY_ROLE_ARN=$(terraform output -raw terraform_apply_role_arn)

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Add these secrets to GitHub:"
echo "AWS_TERRAFORM_PLAN_ROLE_ARN: $PLAN_ROLE_ARN"
echo "AWS_TERRAFORM_APPLY_ROLE_ARN: $APPLY_ROLE_ARN"
echo ""