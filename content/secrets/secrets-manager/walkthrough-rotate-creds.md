---
title: "Rotate the credentials"
chapter: false
weight: 34
---

In order to trigger a credential rotation - at the Cloud9 terminal enter:

```bash
aws secretsmanager get-secret-value --secret-id serverless-credentials --query SecretString --output text | jq
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
aws secretsmanager rotate-secret --secret-id serverless-credentials | jq
```

The output will look like:
```json
{
  "ARN": "arn:aws:secretsmanager:us-west-2:yyyyyyyyyy:secret:serverless-credentials-zzzz",
  "Name": "serverless-credentials",
  "VersionId": "7d3bd47e-e6a8-4960-a9a2-8d5a52ee2a9b"
}
```
This will result in a JSON object returned that show the secret credential rotation started.   Checking the web app in the browser, the data coming from the database is empty. 

Give this a few mins, then query Secrets Manager again to get the value of the new password to ensure the password has been rotated:
```bash
aws secretsmanager get-secret-value --secret-id serverless-credentials --query SecretString --output text | jq
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

Now that the secret password has been changed, the ECS cluster needs to pick up the new value.   This can be done in many ways but for tutorial purposes force a new deployment of the ECS Fargate Service.
```bash
aws ecs update-service --cluster FargateClusterDemo --service FargateServiceDemo --force-new-deployment --desired-count 1 
```

After a few minutes, the web app will again show the data appropriately.   Check the ECS Console for progress.   