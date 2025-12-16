output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "task_execution_role_arn" {
  description = "ARN of the task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "autoscaling_target_resource_id" {
  description = "Resource ID of the autoscaling target"
  value       = var.enable_autoscaling ? aws_appautoscaling_target.ecs[0].resource_id : null
}

output "scale_up_policy_arn" {
  description = "ARN of the scale up policy"
  value       = var.enable_autoscaling ? aws_appautoscaling_policy.scale_up[0].arn : null
}

output "scale_down_alarm_arn" {
  description = "ARN of the scale down CloudWatch alarm"
  value       = var.enable_autoscaling ? aws_cloudwatch_metric_alarm.cpu_low[0].arn : null
}