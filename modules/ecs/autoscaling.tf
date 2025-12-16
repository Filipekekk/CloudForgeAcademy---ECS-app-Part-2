# Application Auto Scaling Target
resource "aws_appautoscaling_target" "ecs" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.max_count
  min_capacity       = var.min_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.main]
}

# Target Tracking Policy - CPU > 50%
resource "aws_appautoscaling_policy" "scale_up" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.name_prefix}-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 50.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# CloudWatch Alarm - CPU < 25% for 5 minutes
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count = var.enable_autoscaling ? 1 : 0

  alarm_name          = "${var.name_prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 25.0
  alarm_description   = "Triggers when CPU < 25% for 5 consecutive minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_down[0].arn]

  tags = {
    Name = "${var.name_prefix}-cpu-low-alarm"
  }
}

# Step Scaling Policy - Scale down
resource "aws_appautoscaling_policy" "scale_down" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.name_prefix}-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}