#!/bin/bash

# Define variables
TASK_FAMILY="ccf-platform"
SERVICE_NAME="ccf-platform"
NEW_DOCKER_IMAGE="903054967221.dkr.ecr.us-east-1.amazonaws.com/ccf-platform:${BUILD_NUMBER}"
CLUSTER_NAME="ccf-platform"

# Fetch the current task definition JSON
OLD_TASK_DEF=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY --region us-east-1)

echo "OLD_TASK_DEF:"
echo "$OLD_TASK_DEF"

# Update the image in the task definition JSON
NEW_TASK_DEF=$(echo $OLD_TASK_DEF | jq --arg NDI $NEW_DOCKER_IMAGE '.taskDefinition.containerDefinitions[0].image=$NDI')

echo "NEW_TASK_DEF:"
echo "$NEW_TASK_DEF"

# Extract only required fields for registering the new task definition
FINAL_TASK=$(echo $NEW_TASK_DEF | jq '.taskDefinition|{family: .family, volumes: .volumes, containerDefinitions: .containerDefinitions}')

echo "FINAL_TASK:"
echo "$FINAL_TASK"

# Register the new task definition
aws ecs register-task-definition --family $TASK_FAMILY --region us-east-1 --cli-input-json "$FINAL_TASK"

# Update the ECS service with the new task definition
aws ecs update-service --service $SERVICE_NAME --task-definition $TASK_FAMILY --cluster $CLUSTER_NAME --region us-east-1
