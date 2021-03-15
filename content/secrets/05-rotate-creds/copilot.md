---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Start by getting the id of the secret then using it to fetch the actual secret value.   Here we grab the copilot application name, service name, and current environment.

```bash
APP=$(copilot svc show --json | jq -r .application)
SVC=$(copilot svc show --json | jq -r .service)
CENV=$(copilot svc show --json | jq -r .configurations[].environment)
aws secretsmanager get-secret-value --secret-id $APP/$CENV/$SVC/aurora-pg --query SecretString --output text | jq
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
Then rotate the secret via the CLI:

```bash
aws secretsmanager rotate-secret --secret-id $APP/$CENV/$SVC/aurora-pg | jq
```

The output will look like:
```json
{
    "VersionId": "5bdcd897-0a60-44e7-aee0-14c44abec425", 
    "Name": "ecsworkshop/test/todo-app/aurora-pg", 
    "ARN": "arn:aws:secretsmanager:us-west-2:xxxxxxxxxx:secret:ecsworkshop/test/todo-app/aurora-pg-jzAIx2"
}
```
Checking the web app in the browser, the data coming from the database is empty (no todo items will show - just the app scaffolding). 

Next, query Secrets Manager again to get the value of the new password to ensure the password has been rotated:
```bash
aws secretsmanager get-secret-value --secret-id $APP/$CENV/$SVC/aurora-pg --query SecretString --output text | jq
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

Now that the secret password has been changed, the ECS service running task is still using the now-stale secret.   In order for the service to pick up the new secret, stop the running task and let the ECS Scheduler bring up a new task which will contain the updated secret.   

Use the AWS CLI to stop the current task, and then give the service a few mins to launch a new task to get the desired count back to 1. 

```bash
CLUSTER_ARN=$(aws ecs list-clusters | jq -r .clusterArns[])
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_ARN | jq -r .taskArns[])
aws ecs stop-task --cluster $CLUSTER_ARN --task $TASK_ARN | jq

```

Once the task is running, go back to the todo app and refresh, you should see a fully functional app once again. 