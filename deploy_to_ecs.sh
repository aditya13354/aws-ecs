#!/bin/bash

# Define variables
TASK_FAMILY="ccf-platform"  # Task definition family
SERVICE_NAME="ccf-platform"  # ECS service name
NEW_DOCKER_IMAGE="903054967221.dkr.ecr.us-east-1.amazonaws.com/ccf-platform:${BUILD_NUMBER}"  # New Docker image with Jenkins build number
CLUSTER_NAME="ccf-platform"  # ECS cluster name
CPU="256"  # CPU units for Fargate task
MEMORY="512"  # Memory in MiB for Fargate task

# Fetch the AWS credentials from environment variables injected by Jenkins
AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
AWS_DEFAULT_REGION="us-east-1"  # Set the AWS region

# Fetch the current task definition ARN
OLD_TASK_DEF=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query "services[0].taskDefinition" --output text)

echo "Current Task Definition ARN: $OLD_TASK_DEF"

# Register new task definition with updated Docker image
NEW_TASK_DEF=$(aws ecs register-task-definition \
  --family $TASK_FAMILY \
  --container-definitions "[{
    \"name\": \"$TASK_FAMILY\",
    \"image\": \"$NEW_DOCKER_IMAGE\",
    \"cpu\": $CPU,
    \"memory\": $MEMORY,
    \"essential\": true
  }]" \
  --query "taskDefinition.taskDefinitionArn" \
  --output text)

echo "New Task Definition ARN: $NEW_TASK_DEF"

# Update ECS service with the new task definition
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --task-definition $NEW_TASK_DEF

# Deregister old task definitions (optional)
echo "Deregistering old task definitions..."
OLD_TASK_DEFS=$(aws ecs list-task-definitions --family-prefix $TASK_FAMILY --status ACTIVE --query "taskDefinitionArns[0:-1]" --output json)
for task_def in $(echo $OLD_TASK_DEFS | jq -r '.[]'); do
  echo "Deregistering task definition: $task_def"
  aws ecs deregister-task-definition --task-definition $task_def
done

echo "ECS service deployment complete!"
