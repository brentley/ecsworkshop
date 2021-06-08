---
title: "Application Deploy"
disableToc: true
hidden: true
---
 
#### Set the environment variables from what we deployed in the previous step

In order to deploy a service in the VPC, there are resources from the environment built that will need to be referenced. These include subnets, security groups, ECS cluster, EFS file system id, and so on. 

Run the following to export all of the resource values that we will need to reference:

```bash
export cloudformation_outputs=$(aws cloudformation describe-stacks --stack-name ecsworkshop-efs-fargate-demo | jq .Stacks[].Outputs)
export cluster_name=$(aws cloudformation describe-stacks --stack-name ecsworkshop-base | jq -r '.Stacks[].Outputs[] | select(.ExportName != null) | select(.ExportName | contains("ECSClusterName"))| .OutputValue')
export execution_role_arn=$(echo $cloudformation_outputs | jq -r '.[]| select(.ExportName | contains("ECSFargateEFSDemoTaskExecutionRoleARN"))| .OutputValue')
export fs_id=$(echo $cloudformation_outputs | jq -r '.[]| select(.ExportName | contains("ECSFargateEFSDemoFSID"))| .OutputValue')
export target_group_arn=$(echo $cloudformation_outputs | jq -r '.[]| select(.ExportName | contains("ECSFargateEFSDemoTGARN"))| .OutputValue')
export private_subnets=$(echo $cloudformation_outputs | jq -r '.[]| select(.ExportName | contains("ECSFargateEFSDemoPrivSubnets"))| .OutputValue')
export security_groups=$(echo $cloudformation_outputs | jq -r '.[]| select(.ExportName | contains("ECSFargateEFSDemoSecGrps"))| .OutputValue')
export load_balancer_url=$(echo $cloudformation_outputs | jq -r '.[]| select(.ExportName | contains("ECSFargateEFSDemoLBURL"))| .OutputValue')
export log_group_name=$(echo $cloudformation_outputs | jq -r '.[]| select(.ExportName | contains("ECSFargateEFSDemoLogGroupName"))| .OutputValue')
export container_name="cloudcmd-rw"
``` 
 
#### Create the task definition

In ECS, the first step to getting a container (or containers) running is to define the task definition. The task definition will define our desired state of how we want to operate our docker containers. 

Feel free to review the file `task_definition.json`. In this task definition, we define how and where to log the container logs, memory/cpu requirements, port mappings, and most importantly (with regards to this workshop) our container mount point to the EFS mount. There's much more to review, but those are some high level items.

For more information on a task definition, see [here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html).

First we need to populate some of the values in the definition from the environment we created in step 1.

```bash
  sed "s|{{EXECUTIONROLEARN}}|$execution_role_arn|g;s|{{TASKROLEARN}}|$task_role_arn|g;s|{{FSID}}|$fs_id|g;s|{{LOGGROUPNAME}}|$log_group_name|g;s|{{REGION}}|$AWS_REGION|g" task_definition.json > task_definition.automated
```
  
Next, it's time to create the task definition. We export the output from the task definition into an environment variable that we will use when deploying the service.
```bash
  export task_definition_arn=$(aws ecs register-task-definition --cli-input-json file://"$PWD"/task_definition.automated | jq -r .taskDefinition.taskDefinitionArn)
```

#### Create the Service

With a Task Definition created, we can now create a service. The service will take that desired state of our container, and ensure that we always run `n` number of tasks, as well as placing the tasks behind the Load Balancer that we created in step 1.

For more information on services in ECS, see [here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html).

Run the following command to create the service:

```bash
  aws ecs create-service \
  --cluster $cluster_name \
  --service-name cloudcmd-rw \
  --task-definition "$task_definition_arn" \
  --load-balancers targetGroupArn="$target_group_arn",containerName="$container_name",containerPort=8000 \
  --desired-count 1 \
  --platform-version 1.4.0 \
  --launch-type FARGATE \
  --deployment-configuration maximumPercent=100,minimumHealthyPercent=0 \
  --network-configuration "awsvpcConfiguration={subnets=["$private_subnets"],securityGroups=["$security_groups"],assignPublicIp=DISABLED}"
```

At this point, we have deployed a Fargate ECS Service with an expectation of 1 task to be running. Let's interact with the app and see the stateful backend work in realtime.
