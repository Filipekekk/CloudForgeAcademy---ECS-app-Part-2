# Data source for GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # To są publiczne odciski palca certyfikatów GitHub (wymagane przez AWS)
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}
# Trust Policy for GitHub Actions
locals {
  github_org  = var.github_organization
  github_repo = var.github_repository

  github_oidc_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${local.github_org}/${local.github_repo}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

# IAM Role for Terraform Plan (Read-Only)
resource "aws_iam_role" "terraform_plan" {
  name               = "${var.name_prefix}-terraform-plan-role"
  assume_role_policy = local.github_oidc_trust_policy

  tags = {
    Name = "${var.name_prefix}-terraform-plan-role"
  }
}

# Policy for Terraform Plan
resource "aws_iam_role_policy" "terraform_plan" {
  name = "${var.name_prefix}-terraform-plan-policy"
  role = aws_iam_role.terraform_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ecs:Describe*",
          "ecs:List*",
          "ecr:Describe*",
          "ecr:List*",
          "elasticloadbalancing:Describe*",
          "logs:Describe*",
          "logs:List*",
          "autoscaling:Describe*",
          "application-autoscaling:Describe*",
          "cloudwatch:Describe*",
          "cloudwatch:List*",
          "cloudwatch:Get*",
          "iam:Get*",
          "iam:List*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}",
          "arn:aws:s3:::${var.terraform_state_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/${var.terraform_lock_table}"
      }
    ]
  })
}

# IAM Role for Terraform Apply (Full Access)
resource "aws_iam_role" "terraform_apply" {
  name               = "${var.name_prefix}-terraform-apply-role"
  assume_role_policy = local.github_oidc_trust_policy

  tags = {
    Name = "${var.name_prefix}-terraform-apply-role"
  }
}

# Policy for Terraform Apply
resource "aws_iam_role_policy_attachment" "terraform_apply_admin" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}