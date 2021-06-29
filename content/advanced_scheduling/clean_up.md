---
title: Clean Up
chapter: false
weight: 60
---

Delete the CloudFormation stack created for this workshop.

```bash
$ aws autoscaling update-auto-scaling-group --auto-scaling-group-name GpuECSAutoScalingGroup --no-new-instances-protected-from-scale-in
$ aws autoscaling update-auto-scaling-group --auto-scaling-group-name ArmECSAutoScalingGroup --no-new-instances-protected-from-scale-in
$ aws cloudformation delete-stack --stack-name ecs-demo
$ aws cloudformation delete-stack --stack-name ecsworkshop-vpc

```