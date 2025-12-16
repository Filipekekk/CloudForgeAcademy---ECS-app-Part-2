.PHONY: help init plan apply destroy fmt validate lint test clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $1, $2}'

init: ## Initialize Terraform
	terraform init

plan: ## Show Terraform plan
	terraform plan -out=tfplan

apply: ## Apply Terraform configuration
	terraform apply tfplan

destroy: ## Destroy all resources
	terraform destroy

fmt: ## Format Terraform files
	terraform fmt -recursive

validate: ## Validate Terraform configuration
	terraform validate

lint: ## Run TFLint
	tflint --init && tflint

test: fmt validate lint ## Run all tests

clean: ## Clean Terraform files
	rm -rf .terraform .terraform.lock.hcl terraform.tfstate* tfplan

# Docker commands
docker-build: ## Build Docker image
	cd app && docker build --platform linux/amd64 -t hello-world-app .

docker-run: ## Run Docker container
	docker run -d -p 8080:8080 --name hello-world-app hello-world-app

docker-test: ## Test Docker container
	@sleep 3 && curl -f http://localhost:8080/health && curl http://localhost:8080/

docker-stop: ## Stop Docker container
	docker stop hello-world-app || true && docker rm hello-world-app || true

# AWS commands
aws-login-ecr: ## Login to ECR
	$(eval ECR_URL := $(shell terraform output -raw ecr_repository_url | cut -d'/' -f1))
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(ECR_URL)

aws-push: aws-login-ecr ## Push image to ECR
	$(eval ECR_URL := $(shell terraform output -raw ecr_repository_url))
	docker tag hello-world-app:latest $(ECR_URL):latest
	docker push $(ECR_URL):latest

# Monitoring
logs: ## Tail CloudWatch logs
	aws logs tail /ecs/static-website-dev-app --follow

ecs-status: ## Show ECS service status
	aws ecs describe-services \
		--cluster static-website-dev-cluster \
		--services static-website-dev-service \
		--query 'services[0].{desired:desiredCount,running:runningCount}' \
		--output table

scaling-activity: ## Show autoscaling activity
	aws application-autoscaling describe-scaling-activities \
		--service-namespace ecs \
		--resource-id service/static-website-dev-cluster/static-website-dev-service \
		--max-results 10

# Load testing
load-test: ## Run load test
	$(eval ALB_URL := $(shell terraform output -raw alb_url))
	ab -n 10000 -c 50 $(ALB_URL)/