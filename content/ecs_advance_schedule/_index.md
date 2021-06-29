---
title: Advanced Scheduling techniques on ECS
chapter: false
weight: 56
---
### 1. Introduction

In this walkthrough, we will dive into more advanced scheduling scenarios for your tasks running on Amazon ECS. 
When a task requiring EC2 compute is launched, Amazon ECS must determine where to place the task based on the requirements specified in the task definition, such as CPU and memory.
But what happens when you need to go beyond the basics of ensuring CPU and Memory requirements are met, and want to have more control over how tasks get placed into the cluster?
This is where scheduling techniques such as placement constraints and placement strategies can help. 
We will focus on how to schedule tasks based on specialty use cases including tasks that require GPU as well as ARM support. 
Using two types of ECS optimized AMI's (ARM and GPU) we will register the container instances to the same ECS Cluster to learn how to place the specific tasks on the desired container instance based on the task requirements.
Before we get started, let's walk through the process that Amazon ECS follows when placing task to select the desired container instance:

1. Identifies the instance that satisfies the CPU, Memory and port requirements in that task definition
2. Identifies the instances that satisfies the task [placement constraints](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-constraints.html). 
3. Identifies the instances that satisfies the task [placment strategies](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement-strategies.html).
4. Selects the instances for task placement. 


With the above knowledge, let’s get started with a walk through of ECS task placement.