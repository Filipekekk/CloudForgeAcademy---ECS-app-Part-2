#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🔥 ECS Auto-Scaling Test${NC}"

cd ../part3
ALB_URL=$(terraform output -raw alb_url 2>/dev/null || echo "")
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "static-website-dev-cluster")
SERVICE_NAME=$(terraform output -raw ecs_service_name 2>/dev/null || echo "static-website-dev-service")

if [ -z "$ALB_URL" ]; then
    echo -e "${RED}❌ Could not get ALB URL${NC}"
    exit 1
fi

echo "ALB URL: $ALB_URL"
echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"
echo ""

# Get current state
get_task_count() {
    aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --query 'services[0].{desired:desiredCount,running:runningCount}' \
        --output json
}

get_cpu() {
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ECS \
        --metric-name CPUUtilization \
        --dimensions Name=ClusterName,Value=$CLUSTER_NAME Name=ServiceName,Value=$SERVICE_NAME \
        --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 60 \
        --statistics Average \
        --query 'Datapoints[-1].Average' \
        --output text
}

echo -e "${YELLOW}📊 Initial State:${NC}"
INITIAL_STATE=$(get_task_count)
echo "$INITIAL_STATE" | jq '.'
INITIAL_COUNT=$(echo "$INITIAL_STATE" | jq -r '.desired')

echo -e "${YELLOW}🔥 Generating Load...${NC}"

# Check for apache bench
if ! command -v ab &> /dev/null; then
    echo "Installing apache2-utils..."
    sudo apt-get update && sudo apt-get install -y apache2-utils
fi

# Generate load
ab -n 50000 -c 50 -t 300 $ALB_URL/ > /dev/null 2>&1 &
LOAD_PID=$!

echo -e "${GREEN}✓ Load generation started${NC}"
echo ""

# Monitor for scale-out
echo -e "${YELLOW}⏳ Monitoring for scale-out...${NC}"
for i in {1..60}; do
    sleep 5
    
    CURRENT_STATE=$(get_task_count)
    CURRENT_COUNT=$(echo "$CURRENT_STATE" | jq -r '.desired')
    CPU=$(get_cpu)
    
    echo -ne "\r[$i/60] Tasks: $CURRENT_COUNT | CPU: ${CPU}%   "
    
    if [ "$CURRENT_COUNT" -gt "$INITIAL_COUNT" ]; then
        echo ""
        echo -e "${GREEN}✅ Scale-out detected!${NC}"
        echo "$CURRENT_STATE" | jq '.'
        break
    fi
done

# Stop load
kill $LOAD_PID 2>/dev/null || true
echo -e "${GREEN}✓ Load generation stopped${NC}"

echo -e "${GREEN}✅ Test complete!${NC}"