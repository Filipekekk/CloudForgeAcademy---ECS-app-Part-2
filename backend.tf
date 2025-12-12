terraform {
  backend "s3" {
    bucket         = "fwojcik-ecs-tfstate-s3"
    key            = "ecs-fargate-app/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}