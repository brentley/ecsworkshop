---
title: "Embedded tab content"
disableToc: true
hidden: true
---


Let’s bring up the Crystal Backend API!

## Deploy our crystal application:
```
cd ~/environment/ecsdemo-crystal
envsubst < ecs-params.yml.template >ecs-params.yml

ecs-cli compose --project-name ecsdemo-crystal service up \
    --create-log-groups \
    --private-dns-namespace service \
    --enable-service-discovery \
    --cluster-config container-demo \
    --vpc $vpc
    
```
Here, we change directories into our crystal application code directory.
The `envsubst` command templates our `ecs-params.yml` file with our current values.
We then launch our crystal service on our ECS cluster (with a default launchtype 
of Fargate)

Note: ecs-cli will take care of building our private dns namespace for service discovery,
and log group in cloudwatch logs.

## View running container, and store the output of the task id as an env variable for later use:
```
ecs-cli compose --project-name ecsdemo-crystal service ps \
    --cluster-config container-demo

task_id=$(ecs-cli compose --project-name ecsdemo-crystal service ps --cluster-config container-demo | awk -F \/ 'FNR == 2 {print $2}')
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
ecs-cli compose --project-name ecsdemo-crystal service scale 3 \
    --cluster-config container-demo
ecs-cli compose --project-name ecsdemo-crystal service ps \
    --cluster-config container-demo
```
We can see that our containers have now been evenly distributed across all 3 of our
availability zones.
