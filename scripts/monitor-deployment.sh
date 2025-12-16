#!/bin/bash

CLUSTER_NAME="${1:-static-website-dev-cluster}"
SERVICE_NAME="${2:-static-website-dev-service}"

echo "🔍 Monitoring ECS Service: $SERVICE_NAME"
echo "Press Ctrl+C to stop"

while true; do
    clear
    echo "=== ECS Service Status ==="
    echo "Time: $(date)"
    echo ""
    
    aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --query 'services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount}' \
        --output table
    
    echo ""
    echo "=== Recent Events ==="
    aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --query 'services[0].events[0:5]' \
        --output table
    
    sleep 10
done