#!/bin/bash

# Define variables
TASK_FAMILY="ccf-platform"
SERVICE_NAME="ccf-platform"
NEW_DOCKER_IMAGE="903054967221.dkr.ecr.us-east-1.amazonaws.com/ccf-platform:${BUILD_NUMBER}"
CLUSTER_NAME="ccf-platform"


# Export the AWS credentials as environment variables
ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_REGION='us-east-1'
# Fetch the current task definition JSON
OLD_TASK_DEF=$(aws ecs describe-task-definition --task-definition $TASK_FAMILY)

echo "OLD_TASK_DEF:"
echo "$OLD_TASK_DEF"

# Check if task definition exists
if [ -z "$OLD_TASK_DEF" ]; then
    echo "Error: Task definition not found."
    exit 1
fi

# Update the image in the task definition JSON
NEW_TASK_DEF=$(echo $OLD_TASK_DEF | jq --arg NDI $NEW_DOCKER_IMAGE '.taskDefinition.containerDefinitions[0].image=$NDI')

echo "NEW_TASK_DEF:"
echo "$NEW_TASK_DEF"

# Check if new task definition is empty
if [ -z "$NEW_TASK_DEF" ]; then
    echo "Error: Failed to update task definition."
    exit 1
fi

# Extract only required fields for registering the new task definition
FINAL_TASK=$(echo $NEW_TASK_DEF | jq '.taskDefinition|{family: .family, volumes: .volumes, containerDefinitions: .containerDefinitions}')

echo "FINAL_TASK:"
echo "$FINAL_TASK"

# Check if final task definition is empty
if [ -z "$FINAL_TASK" ]; then
    echo "Error: Invalid JSON format for task definition."
    exit 1
fi

# Register the new task definition
aws ecs register-task-definition --family $TASK_FAMILY --cli-input-json "$FINAL_TASK"

# Update the ECS service with the new task definition
aws ecs update-service --service $SERVICE_NAME --task-definition $TASK_FAMILY --cluster $CLUSTER_NAME
