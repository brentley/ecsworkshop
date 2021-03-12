---
title: "Embedded tab content"
disableToc: true
hidden: true
---
```bash
SECRET_ID=$(jq -r '.RDSStack.SecretName' result.json)
aws secretsmanager get-secret-value --secret-id $SECRET_ID --query SecretString --output text | jq
```

to get the current value of the secret stored in Secrets Manager.   
```json
{
  "dbClusterIdentifier": "rdsstack-postgresrdsserverless",
  "password": "OLD_PASSWORD",
  "dbname": "tododb",
  "engine": "postgres",
  "port": 5432,
  "host": "rdsstack-xxxxxxxx.us-west-2.rds.amazonaws.com",
  "username": "postgres"
}
```
Then rotate the secret:

```bash
aws secretsmanager rotate-secret --secret-id $SECRET_ID | jq
```

The output will look like:
```json
{
    "VersionId": "5bdcd897-0a60-44e7-aee0-14c44abec425", 
    "Name": "ecsworkshop/test/todo-app/aurora-pg", 
    "ARN": "arn:aws:secretsmanager:us-west-2:xxxxxxxxxx:secret:ecsworkshop/test/todo-app/aurora-pg-jzAIx2"
}
```
This will result in a JSON object returned that shows the secret credential rotation started.   Checking the web app in the browser, the data coming from the database is empty. 

Give this a few seconds, then query Secrets Manager again to get the value of the new password to ensure the password has been rotated:
```bash
aws secretsmanager get-secret-value --secret-id $SECRET_ID --query SecretString --output text | jq
```
Output:
```json
{
  "dbClusterIdentifier": "rdsstack-postgresrdsserverless",
  "password": "MYSUPERNEWSUPERSECRETPASSWORD123",
  "dbname": "tododb",
  "engine": "postgres",
  "port": 5432,
  "host": "rdsstack-xxxxxxxx.us-west-2.rds.amazonaws.com",
  "username": "postgres"
}
```

Now that the secret password has been changed, the ECS task definition is still using the now-stale secret.   We need to force a new deployment of the app to update the credential for the application.  


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