---
title: "Embedded tab content"
disableToc: true
hidden: true
---

## Set environment variables from our build
```
export clustername=$(aws cloudformation describe-stacks --stack-name container-demo --query 'Stacks[0].Outputs[?OutputKey==`ClusterName`].OutputValue' --output text)
export target_group_arn=$(aws cloudformation describe-stack-resources --stack-name container-demo-alb | jq -r '.[][] | select(.ResourceType=="AWS::ElasticLoadBalancingV2::TargetGroup").PhysicalResourceId')
export vpc=$(aws cloudformation describe-stacks --stack-name container-demo --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' --output text)
export ecsTaskExecutionRole=$(aws cloudformation describe-stacks --stack-name container-demo --query 'Stacks[0].Outputs[?OutputKey==`ECSTaskExecutionRole`].OutputValue' --output text)
export subnet_1=$(aws cloudformation describe-stacks --stack-name container-demo --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnetOne`].OutputValue' --output text)
export subnet_2=$(aws cloudformation describe-stacks --stack-name container-demo --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnetTwo`].OutputValue' --output text)
export subnet_3=$(aws cloudformation describe-stacks --stack-name container-demo --query 'Stacks[0].Outputs[?OutputKey==`PrivateSubnetThree`].OutputValue' --output text)
export security_group=$(aws cloudformation describe-stacks --stack-name container-demo --query 'Stacks[0].Outputs[?OutputKey==`ContainerSecurityGroup`].OutputValue' --output text)

cd ~/environment
```

## Configure `ecs-cli` to talk to your cluster:
```
ecs-cli configure --region $AWS_REGION --cluster $clustername --default-launch-type EC2 --config-name container-demo
```
We set a default region so we can reference the region when we run our commands.

## Authorize traffic:
```
aws ec2 authorize-security-group-ingress --group-id "$security_group" --protocol tcp --port 3000 --source-group "$security_group"
```
We know that our containers talk on port 3000, so authorize that traffic on our security group:

## Deploy our frontend application:
```
cd ~/environment/ecsdemo-frontend
envsubst < ecs-params.yml.template >ecs-params.yml

ecs-cli compose --project-name ecsdemo-frontend service up \
    --create-log-groups \
    --target-group-arn $target_group_arn \
    --private-dns-namespace service \
    --enable-service-discovery \
    --container-name ecsdemo-frontend \
    --container-port 3000 \
    --cluster-config container-demo \
    --vpc $vpc
    
```
Here, we change directories into our frontend application code directory.
The `envsubst` command templates our `ecs-params.yml` file with our current values.
We then launch our frontend service on our ECS cluster (with a default launchtype 
of Fargate)

Note: ecs-cli will take care of building our private dns namespace for service discovery,
and log group in cloudwatch logs.

## View running container, and store the output of the task id as an env variable for later use:
```
ecs-cli compose --project-name ecsdemo-frontend service ps \
    --cluster-config container-demo

task_id=$(ecs-cli compose --project-name ecsdemo-frontend service ps --cluster-config container-demo | awk -F \/ 'FNR == 2 {print $2}')
```
We should have one task registered.

## Check reachability (open url in your browser):
```
alb_url=$(aws cloudformation describe-stacks --stack-name container-demo-alb --query 'Stacks[0].Outputs[?OutputKey==`ExternalUrl`].OutputValue' --output text)
echo "Open $alb_url in your browser"
```
This command looks up the URL for our ingress ALB, and outputs it. You should 
be able to click to open, or copy-paste into your browser.

## View logs:
```
# Referencing task id from above ps command
ecs-cli logs --task-id $task_id \
    --follow --cluster-config container-demo
```
To view logs, find the task id from the earlier `ps` command, and use it in this
command. You can follow a task's logs also.

## Scale the tasks:
```
ecs-cli compose --project-name ecsdemo-frontend service scale 3 \
    --cluster-config container-demo
ecs-cli compose --project-name ecsdemo-frontend service ps \
    --cluster-config container-demo
```
We can see that our containers have now been evenly distributed across all 3 of our
availability zones.
