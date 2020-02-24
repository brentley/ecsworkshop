---
title: "Embedded tab content"
disableToc: true
hidden: true
---

## Deploy our NodeJS Backend Application:
```
cd ~/environment/ecsdemo-nodejs
envsubst < ecs-params.yml.template >ecs-params.yml

ecs-cli compose --project-name ecsdemo-nodejs service up \
    --create-log-groups \
    --private-dns-namespace service \
    --enable-service-discovery \
    --cluster-config fargate-demo \
    --vpc $vpc
    
```
Here, we change directories into our nodejs application code directory.
The `envsubst` command templates our `ecs-params.yml` file with our current values.
We then launch our nodejs service on our ECS cluster (with a default launchtype 
of Fargate)

Note: ecs-cli will take care of building our private dns namespace for service discovery,
and log group in cloudwatch logs.

## View running container:
```
ecs-cli compose --project-name ecsdemo-nodejs service ps \
    --cluster-config fargate-demo
```
We should have one task registered.

## Check reachability (open url in your browser):
```
alb_url=$(aws cloudformation describe-stacks --stack-name fargate-demo-alb --query 'Stacks[0].Outputs[?OutputKey==`ExternalUrl`].OutputValue' --output text)
echo "Open $alb_url in your browser"
```
This command looks up the URL for our ingress ALB, and outputs it. You should 
be able to click to open, or copy-paste into your browser.

## View logs:
```
#substitute your task id from the ps command 
ecs-cli logs --task-id a06a6642-12c5-4006-b1d1-033994580605 \
    --follow --cluster-config fargate-demo
```
To view logs, find the task id from the earlier `ps` command, and use it in this
command. You can follow a task's logs also.

## Scale the tasks:
```
ecs-cli compose --project-name ecsdemo-nodejs service scale 3 \
    --cluster-config fargate-demo
ecs-cli compose --project-name ecsdemo-nodejs service ps \
    --cluster-config fargate-demo
```
We can see that our containers have now been evenly distributed across all 3 of our
availability zones.

