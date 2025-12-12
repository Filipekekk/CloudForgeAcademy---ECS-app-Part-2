
# ECS Fargate Application with Terraform

This project provisions a "Hello World" Python Flask application on AWS ECS Fargate using Terraform.

## Architecture

- **VPC**: Custom VPC with 2 public and 2 private subnets across 2 AZs
- **ECS Fargate**: Containerized Flask app running on Fargate
- **ALB**: Application Load Balancer in public subnets
- **ECR**: Private container registry
- **CloudWatch**: Centralized logging

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Docker installed locally
- AWS Account with appropriate permissions

## Repository Structure

```
part2/
├── README.md                 # This file
├── main.tf                   # Root module orchestration
├── variables.tf              # Variable definitions
├── outputs.tf                # Output values
├── terraform.tfvars          # Variable values
├── versions.tf               # Terraform & provider versions
├── backend.tf                # Remote state configuration
├── locals.tf                 # Common tags and locals
├── app/                      # Application code
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
└── modules/                  # Terraform modules
    ├── networking/
    ├── ecr/
    ├── ecs/
    ├── alb/
    └── cloudwatch/
```

## Setup Instructions

### 1. Prepare Backend (One-time setup)

Before using this project, create the S3 bucket and DynamoDB table for state management:

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket your-terraform-state-bucket \
  --region eu-central-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1
```

### 2. Build and Push Docker Image

```bash
# Navigate to app directory
cd app

# Build Docker image
docker build -t hello-world-app .

# Test locally
docker run -p 8080:8080 hello-world-app
curl http://localhost:8080

# After ECR is created (after first terraform apply), push image
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-central-1.amazonaws.com

docker tag hello-world-app:latest <account-id>.dkr.ecr.eu-central-1.amazonaws.com/<project-name>-dev-app:latest
docker push <account-id>.dkr.ecr.eu-central-1.amazonaws.com/<project-name>-dev-app:latest
```

### 3. Initialize Terraform

```bash
cd CloudForgeAcademy---ECS-app-Part-2
terraform init
```

### 4. Review Changes

```bash
terraform plan
```

### 5. Apply Infrastructure

```bash
terraform apply
```

Review the plan and type `yes` to confirm.

### 6. Access the Application

After successful deployment, get the ALB DNS name:

```bash
terraform output alb_dns_name
```

Visit the URL in your browser:
```
http://<alb-dns-name>
```

Expected response:
```json
{
  "message": "Hello world! Today is year-month-day"
}
```

Health check endpoint:
```
http://<alb-dns-name>/health
```

## Cleanup

To destroy all resources and avoid charges:

```bash
terraform destroy
```

Type `yes` to confirm deletion.

**Important**: Ensure all resources are deleted by checking the AWS Console.

## State Management

This project uses:
- **S3 backend** for remote state storage
- **DynamoDB** for state locking to prevent concurrent modifications

Multiple team members can safely work on this infrastructure without conflicts.

## Customization

Edit `terraform.tfvars` to customize:
- Project name
- AWS region
- VPC CIDR blocks
- ECS task CPU/Memory
- Desired task count

## Troubleshooting

### ECS Task not starting
Check CloudWatch Logs:
```bash
aws logs tail /ecs/hello-world-app --follow
```

### ALB health check failing
Verify security groups allow traffic from ALB to ECS tasks on port 8080.

### Image pull errors
Ensure the Docker image is pushed to ECR and the task execution role has permissions.

## Best Practices Implemented

1. ✅ Modular structure with reusable modules
2. ✅ Remote state with locking
3. ✅ Consistent tagging across all resources
4. ✅ Variables with descriptions and defaults
5. ✅ Version constraints for Terraform and providers
6. ✅ Separate files for concerns (IAM, networking, etc.)
7. ✅ Security: Tasks in private subnets, ALB in public
8. ✅ High availability: Multi-AZ deployment

## License

This project is part of a CloudForge Academy course and is confidential.
```
