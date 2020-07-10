+++
title = "Capacity Providers"
chapter = true
weight = 54
+++

# Amazon ECS Cluster Capacity Providers

{{< youtube V0qyjSvGkJU >}}

In this chapter, we will gain an understanding of how Capacity Providers can help us in managing autoscaling for EC2 backed tasks, as well as ways to implement cost savings when running Fargate tasks.
We will implement two capacity provider strategies in our cluster: 

- For a Fargate backed ECS service, we will implement a strategy to deploy that service as a mix between Fargate and Fargate Spot.

- For an EC2 backed ECS service, we will implement Cluster Auto Scaling by increasing the task count of a service beyond the capacity available. This will require the backend EC2 infrastucture to scale to meet the demand, which the ECS cluster autoscaler will handle.


Let's get started!

