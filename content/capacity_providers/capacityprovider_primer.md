+++
title = "Capacity Providers Primer"
chapter = false
weight = 1
+++

## Overview

Amazon ECS cluster capacity providers determine the infrastructure to use for your tasks. 
Each cluster has one or more capacity providers and an optional default capacity provider strategy. 
The capacity provider strategy determines how the tasks are spread across the capacity providers. 
When you run a task or create a service, you may either use the cluster's default capacity provider strategy or specify a capacity provider strategy that overrides the cluster's default strategy. 

For more information, see the documentation [here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-capacity-providers.html)


## Concepts

Capacity providers can be used for ECS Fargate tasks, and ECS EC2 backed tasks.

- Fargate capacity providers enable you to use both Fargate and Fargate Spot capacity with your Amazon ECS tasks. For more information, see [here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-capacity-providers.html)

- Amazon ECS on EC2 capacity providers enable customers to use Cluster Auto Scaling, allowing the focus of the customer to shift from managing autocaling the backend infrastructure, to focusing on supporting the application.
for more information on Amazon ECS Cluster Auto Scaling, see [here](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-auto-scaling.html)
