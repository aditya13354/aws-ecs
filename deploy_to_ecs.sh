#!/bin/bash

# AWS Credentials
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="YOUR_AWS_REGION"

# ECS Service Details
CLUSTER_NAME="ccf-platform"
SERVICE_NAME="ccf-platform"
NEW_TASK_DEFINITION="ccf-platform"
# Task Definition Revision to Retain
TASK_DEF_REVISION_TO_RETAIN=20

# Update ECS Service
echo "Updating ECS Service..."
aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition $NEW_TASK_DEFINITION

# Deregister old task definitions
echo "Deregistering old task definitions..."
OLD_TASK_DEFS=$(aws ecs list-task-definitions --family-prefix $SERVICE_NAME --status ACTIVE | jq -r ".taskDefinitionArns | sort_by(.)[:-${TASK_DEF_REVISION_TO_RETAIN}] | .[]")
for task_def in $OLD_TASK_DEFS; do
    echo "Deregistering task definition: $task_def"
    aws ecs deregister-task-definition --task-definition $task_def
done

echo "ECS service update complete!"
