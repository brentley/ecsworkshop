---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Start by getting the id of the secret then using it to fetch the actual secret value.  

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

This will result in a JSON object returned that shows the secret credential rotation started.   Checking the web app in the browser, the data coming from the database will be empty.

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

Now that the secret password has been changed, the ECS service running task is still using the now-stale secret.  Remember that we are exposing the secret data to the container app via an environment variable called `POSTGRES_DATA`.  In order for the service to pick up the new secret, stop the running task and let the ECS Scheduler bring up a new task which will contain the updated secret.

You can look at the current value of the secret environment variable available to the container:

```bash
curl -s $url/env | jq -r '.POSTGRES_DATA' | jq
```

After stopping the task - give the scheduler a few minutes to launch a new task to get the desired count back to 1.

```bash
CLUSTER_ARN=$(aws ecs list-clusters | jq -r .clusterArns[])
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_ARN | jq -r .taskArns[])
aws ecs stop-task --cluster $CLUSTER_ARN --task $TASK_ARN | jq
```

Once the task scheduler has started a new task, go back to the todo app and refresh, you should see a fully functional app once again.   You can also check the state of the environment variables again:

```bash
curl -s $url/env | jq -r '.POSTGRES_DATA' | jq
```

which will now reflect the new secret meaning the rotation was successful.
