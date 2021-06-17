---
title: Advanced Scheduling techniques on ECS
chapter: false
weight: 56
---
### 1. Introduction

In this walkthrough, we are going to discuss what happens when an Amazon ECS task that uses the EC2 launch type is launched.  Amazon ECS would determine where to place the task based on the **requirements** specified in the  ECS task definition, such as CPU and memory. Additionally, we are going to use two types of ECS optimized AMI (ARM and GPU) and register the container instances to the same ECS Cluster to learn how to place task(s) on the desired container instance based on the AMI architecture.

When Amazon ECS places task(s), it uses the following process to select the desired container instance:

1. Identifies the instance that satisfies the CPU, Memory and port requirements in that task definition
2. Identifies the instances that satisfies the task [placement constraints](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html). 
3. Identifies the instances that satisfies the task [placment strategies](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-strategies.html).
4. Selects the instances for task placement. 


With the above knowledge, let’s get started with a walk through of ECS task placement.

### 2. What is a Capacity Provider ?

We are going to use ECS Cluster with ECS Capacity Provider. Amazon ECS Capacity providers are used to manage the infrastructure the tasks in your clusters use. Each cluster can have one or more capacity providers and an optional default capacity provider strategy. The capacity provider strategy determines how the tasks are spread across the cluster's capacity providers. When you run a standalone task or create a service, you may either use the cluster's default capacity provider strategy or specify a capacity provider strategy that overrides the cluster's default strategy.

For an in depth walkthrough and demo, check out the [capacity providers](https://ecsworkshop.com/capacity_providers/) section in this workshop.