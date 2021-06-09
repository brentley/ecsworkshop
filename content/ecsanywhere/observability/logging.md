+++
title = "Logging"
description = "Logging"
weight = 1
+++

This section will help walk you through setting up logging for obversability on your ECS-A tasks.

### Pre-requistes

- AWS CLI

### Logging setup in ECS

Logging setup can be different flavors on ECS

These include 

 - json-file
 - syslog 
 - journald
 - gelf
 - fluentd
 - splunk
 - awslogs
 - awsfirelens

We will be covering how to setup the last two flavors which are `awslogs` and `awsfirelens`.

{{% notice note %}}
awsfirelens is a fluent-bit for AWS image. That image is automatically configured and injected as a sidecar task for you 
{{% /notice %}}

### Integration with CloudWatch Logs

For this we need to allow our tasks to communicate with AWS services. Please follow along with the commands to get a better understanding of how to add the capability.

```bash
#Create the log group
aws logs create-log-group --log-group-name ecsanywhere-logs

#Add the policy to our task role
aws iam put-role-policy \
    --role-name ecsanywhereTaskRole \
    --policy-name ecsanywherePolicy \
    --policy-document file://task-role.json

#Add the policy to our task execution role
aws iam put-role-policy \
    --role-name ecsanywhereTaskExecutionRole \
    --policy-name ecsanywherePolicy \
    --policy-document file://task-role.json    

#Register the task definition
envsubst < external-task-definition-logs.json > external-task-definition-logs-replaced.json && aws ecs register-task-definition --cli-input-json file://external-task-definition-logs-replaced.json && rm external-task-definition-logs-replaced.json

#Run the task
aws ecs run-task --cluster $CLUSTER_NAME --launch-type EXTERNAL --task-definition logs

#Get the Task ID
TEST_TASKID=$(aws ecs list-tasks --cluster $CLUSTER_NAME | jq -r '.taskArns[0]')

#Verify Task is Running
aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TEST_TASKID
```

Now if we go to `http://localhost:8080` a few times we should generate some logs, and be able to navigate to AWS and view our log groups.

![Logs](../images/logs.png)

To stop the task

```bash
TEST_TASKID=$(aws ecs list-tasks --cluster $CLUSTER_NAME | jq -r '.taskArns[0]')
aws ecs stop-task --cluster $CLUSTER_NAME --task $TEST_TASKID
```

----

## Integration with Firelens

We can use the same role used in the previous step since Firelens is just a service which creates a `fluent-bit` sidecar for our container logging.

```bash
#Register the task definition
envsubst < external-task-definition-firelens.json > external-task-definition-firelens-replaced.json && aws ecs register-task-definition --cli-input-json file://external-task-definition-firelens-replaced.json && rm external-task-definition-firelens-replaced.json

#Run the task
aws ecs run-task --cluster $CLUSTER_NAME --launch-type EXTERNAL --task-definition firelens

#Get the Task ID
TEST_TASKID=$(aws ecs list-tasks --cluster $CLUSTER_NAME | jq -r '.taskArns[0]')

#Verify Task is Running
aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TEST_TASKID
```

If you look you can find both log groups `ecsanywhere-firelens` and `/aws/ecsanywhere/test-ecs-anywhere` this is showing that firelens is supported and working in our cluster.

![Firelens](../images/firelens.png)

To stop the task

```bash
TEST_TASKID=$(aws ecs list-tasks --cluster $CLUSTER_NAME | jq -r '.taskArns[0]')
aws ecs stop-task --cluster $CLUSTER_NAME --task $TEST_TASKID
```
