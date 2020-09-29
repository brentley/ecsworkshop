---
title: "Capacity Providers"
chapter: true
weight: 54
pre: '<i class="fa fa-film" aria-hidden="true"></i> '
---

# Amazon ECS Cluster Capacity Providers

{{< youtube V0qyjSvGkJU >}}

In this chapter, we will gain an understanding of how Capacity Providers can help us in managing autoscaling for EC2 backed tasks, as well as ways to implement cost savings leveraging spare compute capacity in AWS running tasks on Fargate Spot and EC2 Spot instances.
We will implement three capacity provider strategies in our cluster: 

- For a Fargate backed ECS service, we will implement a strategy to deploy that service as a mix between Fargate and Fargate Spot.

- For an EC2 backed ECS service, we will implement Cluster Auto Scaling by increasing the task count of a service beyond the capacity available. This will require the backend EC2 infrastructure to scale to meet the demand, which the ECS Cluster Autoscaling will handle.

- Finally, we will add a second EC2 capacity provider backed by EC2 Spot instances and scale our EC2 backed service across both On-Demand and Spot EC2 Instances. This will allow us to scale out our service cost effectively while Cluster Autoscaling handles scaling of the underlying infrastructure. 


Let's get started!

