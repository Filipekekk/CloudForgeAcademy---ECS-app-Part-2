# IAM Roles for GitHub OIDC

This directory contains IAM roles for GitHub Actions OIDC authentication.

## Prerequisites

Create GitHub OIDC provider (one-time setup):

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## Usage

1. Create `terraform.tfvars`:

```hcl
github_organization    = "your-username"
github_repository      = "your-repo-name"
terraform_state_bucket = "your-terraform-state-bucket"
terraform_lock_table   = "terraform-state-lock"
```

2. Deploy roles:

```bash
terraform init
terraform apply
```

3. Add role ARNs to GitHub Secrets:
   - `AWS_TERRAFORM_PLAN_ROLE_ARN`
   - `AWS_TERRAFORM_APPLY_ROLE_ARN`

## Roles

**Plan Role**: Read-only access for terraform plan
**Apply Role**: Full access for terraform apply/destroy
