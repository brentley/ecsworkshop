---
title: "Embedded tab content"
disableToc: true
hidden: true
---

Now we are going to add credential rotation to the secret stored in AWS Secrets Manager.  Rotation is a common security best practice.  

First, we are going to add another file to the `addons` directory in which to create the rotation:

```bash
cd ~/environment/secretecs
cat << EOF > copilot/todo-app/addons/rotation.yml
---
AWSTemplateFormatVersion: 2010-09-09
Transform:
  - "AWS::Serverless-2016-10-31"
  
Parameters:
  App:
    Type: String
    Description: Your application's name.
  Env:
    Type: String
    Description: The environment name your service, job, or workflow is being deployed to.
  Name:
    Type: String
    Description: The name of the service, job, or workflow being deployed.

Resources:

    SecretRotationTemplate:
        Type: AWS::Serverless::Application
        Properties:
          Location:
            ApplicationId: arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSPostgreSQLRotationSingleUser
            SemanticVersion: 1.1.60
          Parameters:
            endpoint: !Sub https://secretsmanager.${AWS::Region}.amazonaws.com
            functionName: !Sub ${AWS::StackName}-func
            vpcSecurityGroupIds: !ImportValue RotationSecurityGroup
            vpcSubnetIds:
              Fn::Join:
                - ","
                - - !Select [
                      0,
                      !Split [
                        ",",
                        { "Fn::ImportValue": !Sub "${App}-${Env}-PrivateSubnets" },
                      ],
                    ]
                  - !Select [
                      1,
                      !Split [
                        ",",
                        { "Fn::ImportValue": !Sub "${App}-${Env}-PrivateSubnets" },
                      ],
                    ]
                    
    SecretRotationSchedule:
        Type: AWS::SecretsManager::RotationSchedule
        Properties:
          SecretId: !ImportValue AuroraSecret
          RotationLambdaARN: !GetAtt SecretRotationTemplate.Outputs.RotationLambdaARN
          RotationRules:
            AutomaticallyAfterDays: 30
EOF
```

Here we are adding a RotationTemplate and a RotationSchedule.   The RotationTemplate points to a Lambda ARN that is stored in [Serverless Application Repository](https://aws.amazon.com/serverless/serverlessrepo/).  This will create a new lambda to execute the credential rotation.  You will see it as a nested stack in the Cloudformation console.  The RotationSchedule sets the duration between credential rotations and attaches itself to the Secret defined in the other stack.

Next, we need to commit the change locally and deploy it to the copilot environment.

```bash
git add copilot/todo-app/addons/rotation.yml && git commit -m "Add Credential Rotation"
```

Then we deploy the change with an arbitrary tag to force a new version.   This process take between 5-7 minutes to create the new lambda and attach it to the secret.

```bash
copilot svc deploy --tag update-credentials
```

Now, we will manually rotate the secret to be sure it works.

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
