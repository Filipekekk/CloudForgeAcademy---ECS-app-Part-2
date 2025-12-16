# Networking Module
module "networking" {
  source = "./modules/networking"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  name_prefix          = local.name_prefix
}

# CloudWatch Module
module "cloudwatch" {
  source = "./modules/cloudwatch"

  log_group_name    = "/ecs/${local.name_prefix}-app"
  retention_in_days = 14
  name_prefix       = local.name_prefix
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  repository_name = "${local.name_prefix}-app"
  name_prefix     = local.name_prefix
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  name_prefix       = local.name_prefix
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  container_port    = var.container_port
}

# ECS Module
module "ecs" {
  source = "./modules/ecs"

  name_prefix           = local.name_prefix
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn

  container_image    = var.container_image
  container_port     = var.container_port
  task_cpu           = var.task_cpu
  task_memory        = var.task_memory
  min_count          = var.min_count
  desired_count      = var.desired_count
  max_count          = var.max_count
  enable_autoscaling = var.enable_autoscaling

  log_group_name = module.cloudwatch.log_group_name
  aws_region     = var.aws_region

  depends_on = [module.alb]
}
