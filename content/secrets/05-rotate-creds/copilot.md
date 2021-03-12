---
title: "Embedded tab content"
disableToc: true
hidden: true
---
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
Then rotate the secret:

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
This will result in a JSON object returned that shows the secret credential rotation started.   Checking the web app in the browser, the data coming from the database is empty. 

Give this a few seconds, then query Secrets Manager again to get the value of the new password to ensure the password has been rotated:
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

Now that the secret password has been changed, the ECS task definition is still using the now-stale secret.   We need to force a new deployment of the app to update the credential for the application.  
We use the `copilot` command to trigger a new deployment of the task definition which contains the updated secret. 
```bash
copilot svc deploy --tag update-credentials
```