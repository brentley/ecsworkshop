---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Use the AWS CLI to force a new deployment:

```bash
CLUSTER_ARN=$(aws ecs list-clusters | jq -r .clusterArns[0])
SERVICE_ARN=$(aws ecs list-services --cluster $CLUSTER_ARN | jq -r .serviceArns[0])
CLUSTER_NAME=$(aws ecs describe-clusters --cluster $CLUSTER_ARN | jq -r .clusters[0].clusterName)
SERVICE_NAME=$(aws ecs describe-services --cluster $CLUSTER_ARN --service $SERVICE_ARN | jq -r .services[0].serviceName)
TASK_DEFINITION=$(aws ecs describe-services --cluster $CLUSTER_ARN --services $SERVICE_NAME | jq -r .services[].taskDefinition)
TASK_DEF=$(echo $TASK_DEFINITION | cut -d: -f1-6)  

NEW_TASK_DEFINITION=$(aws ecs describe-task-definition --task-definition $TASK_DEFINITION \
      --query '{  containerDefinitions: taskDefinition.containerDefinitions,
                  family: taskDefinition.family,
                  taskRoleArn: taskDefinition.taskRoleArn,
                  executionRoleArn: taskDefinition.executionRoleArn,
                  networkMode: taskDefinition.networkMode,
                  volumes: taskDefinition.volumes,
                  placementConstraints: taskDefinition.placementConstraints,
                  requiresCompatibilities: taskDefinition.requiresCompatibilities,
                  cpu: taskDefinition.cpu,
                  memory: taskDefinition.memory }' )
TD_VERSION=$(aws ecs register-task-definition --cli-input-json "$NEW_TASK_DEFINITION" \
  --query 'taskDefinition.revision')
  
aws ecs update-service --force-new-deployment --cluster $CLUSTER_NAME --service $SERVICE_NAME --task-definition $TASK_DEF:$TD_VERSION
```