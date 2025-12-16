output "terraform_plan_role_arn" {
  description = "ARN of the Terraform Plan IAM role"
  value       = aws_iam_role.terraform_plan.arn
}

output "terraform_apply_role_arn" {
  description = "ARN of the Terraform Apply IAM role"
  value       = aws_iam_role.terraform_apply.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}