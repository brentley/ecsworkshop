---
title: "Embedded tab content"
disableToc: true
hidden: true
---

## Delete our compute resources, starting with the services, then ALB, then ECS Cluster, VPC, etc...
```
cd ~/environment/ecsdemo-frontend

ecs-cli compose --project-name ecsdemo-crystal service rm --cluster-config container-demo
ecs-cli compose --project-name ecsdemo-nodejs service rm --cluster-config container-demo
ecs-cli compose --project-name ecsdemo-frontend service rm --delete-namespace --cluster-config container-demo

aws cloudformation delete-stack --stack-name container-demo-alb
aws cloudformation wait stack-delete-complete --stack-name container-demo-alb
aws cloudformation delete-stack --stack-name container-demo
    
```
