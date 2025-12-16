output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "URL to access the application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

output "cloudwatch_log_group" {
  description = "Name of the CloudWatch log group"
  value       = module.cloudwatch.log_group_name
}

output "autoscaling_target" {
  description = "Auto Scaling target resource ID"
  value       = module.ecs.autoscaling_target_resource_id
}

output "cloudwatch_logs_url" {
  description = "URL to CloudWatch Logs in AWS Console"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(module.cloudwatch.log_group_name, "/", "$252F")}"
}

output "ecs_service_url" {
  description = "URL to ECS Service in AWS Console"
  value       = "https://console.aws.amazon.com/ecs/v2/clusters/${module.ecs.cluster_name}/services/${module.ecs.service_name}"
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = module.alb.target_group_arn
}